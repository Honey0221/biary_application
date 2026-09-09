import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'
import { 
  NUTRIENT_CODES, 
  calcAchievement, 
  resolveAgeGroupCode, 
  searchFoodApi, 
  estimateByGemini 
} from '../_shared/nutrients.ts'

const GEMINI_KEY = Deno.env.get('GEMINI_API_KEY') ?? ''
const FOOD_API_KEY = Deno.env.get('FOOD_API_KEY') ?? ''

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { preComputedIntake, directInputFoods, childId, childAgeMonths, childGender } 
      = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 직접 입력 음식 처리
    const aiEstimatedFoods: string[] = []
    const directIntake: Record<string, number> = {}

    for (const food of (directInputFoods ?? []) as { 
      name: string; intakeAmountG: number 
    }[]) {
      const ratio = food.intakeAmountG / 100.0
      let nutrients = await searchFoodApi(food.name, FOOD_API_KEY)
      if (!nutrients) {
        nutrients = await estimateByGemini(food.name, GEMINI_KEY)
        aiEstimatedFoods.push(food.name)
      }
      for (const code of NUTRIENT_CODES) {
        const v = (nutrients as Record<string, number | null>)[code]
        if (v != null && v > 0) {
          directIntake[code] = (directIntake[code] ?? 0) + v * ratio
        }
      }
    }

    // 전체 섭취량 합산 (Flutter 계산값 + 직접 입력)
    const totalIntake: Record<string, number> = { ...(preComputedIntake ?? {}) }
    for (const [k, v] of Object.entries(directIntake)) {
      totalIntake[k] = (totalIntake[k] ?? 0) + v
    }

    // DRI 조회
    const ageGroupCode = resolveAgeGroupCode(childAgeMonths, childGender)
    const { data: driRows } = await supabase
      .from('nutrient_reference_by_age')
      .select('nutrient_code, recommended_amount')
      .eq('age_group_code', ageGroupCode)

    const driMap: Record<string, number | null> = {}
    for (const row of driRows ?? []) driMap[row.nutrient_code] = row.recommended_amount

    // 달성률 계산
    const achievement = calcAchievement(totalIntake, driMap, childAgeMonths)

    // 최근 7일 분석 결과 조회
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
    const { data: historyRows } = await supabase
      .from('analysis_results')
      .select('nutrients, target_date')
      .eq('child_id', childId)
      .gte('target_date', since)
      .order('target_date', { ascending: false })
      .limit(7)

    const historySummary = (historyRows ?? [])
      .map((r: { target_date: string; nutrients: Record<string, number> }) => {
        const e = r.nutrients['energy'] ?? 0
        const p = r.nutrients['protein'] ?? 0
        const ca = r.nutrients['calcium'] ?? 0
        return `${r.target_date}: 열량 ${e.toFixed(0)}kcal / 단백질 ${p.toFixed(1)}g / 칼슘 ${ca.toFixed(0)}mg`
      })
      .join('\n')

    // AI 코멘트 2섹션 + 부족 영양소 추천 식품
    const nutrientKr: Record<string, string> = {
      energy: '열량', carbohydrate: '탄수화물', protein: '단백질', fat: '지방',
      sugar: '당류', dietary_fiber: '식이섬유', sodium: '나트륨', calcium: '칼슘',
      iron: '철분', zinc: '아연', vitamin_a: '비타민A', vitamin_c: '비타민C', 
      vitamin_d: '비타민D'
    }

    const deficientCodes = Object.entries(achievement)
      .filter(([, v]) => v < 70).map(([k]) => k)

    const prompt = `소아 영양 전문가로서, 구독 회원의 ${childAgeMonths}개월 아이 식단을 한국어로 상세히 분석해 주세요.

오늘 영양소 달성률: ${Object.entries(achievement).map(([k, v]) => `${nutrientKr[k] ?? k} ${v.toFixed(0)}%`).join(', ')}
${deficientCodes.length > 0 ? `부족 영양소: ${deficientCodes.map(c => nutrientKr[c] ?? c).join(', ')}` : '오늘 전반적으로 양호'}
최근 7일 기록: ${historySummary || '기록 없음'}
${aiEstimatedFoods.length > 0 ? `(AI 추정 음식 포함: ${aiEstimatedFoods.join(', ')})` : ''}

아래 JSON 형식으로만 응답하세요:
{"todayComment":"오늘 분석 2~3문장","trendComment":"최근 7일 트렌드 2~3문장","suggestions":[{"nutrient":"영양소코드","foods":["식품1","식품2"]}]}`

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${GEMINI_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.7, maxOutputTokens: 1024 }
        })
      }
    )
    const geminiData = await geminiRes.json()
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}'
    let todayComment = '', trendComment = ''
    let suggestions: { nutrient: string; foods: string[] }[] = []

    try {
      const cleaned = rawText.replace(/```json\n?|\n?```/g, '').trim()
      const parsed = JSON.parse(cleaned)

      todayComment = parsed.todayComment ?? ''
      trendComment = parsed.trendComment ?? ''
      suggestions = parsed.suggestions ?? []
    } catch {
      todayComment = rawText.trim()
    }

    // 응답
    return new Response(
      JSON.stringify({ 
        nutrients: totalIntake, achievement, todayComment, 
        trendComment, suggestions, aiEstimatedFoods 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    console.error('analyze-full error: ', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})