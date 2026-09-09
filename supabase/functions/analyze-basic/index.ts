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
    const { preComputedIntake, directInputFoods, childAgeMonths, childGender } 
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

    // AI 단락형 코멘트 생성 (미구독 - 히스토리 없음)
    const deficientList = Object.entries(achievement)
      .filter(([, v]) => v < 70).map(([k]) => k).join(', ')

    const nutrientKr: Record<string, string> = {
      energy: '열량', carbohydrate: '탄수화물', protein: '단백질', fat: '지방',
      sugar: '당류', dietary_fiber: '식이섬유', sodium: '나트륨', calcium: '칼슘',
      iron: '철분', zinc: '아연', vitamin_a: '비타민A', vitamin_c: '비타민C', 
      vitamin_d: '비타민D'
    }

    const prompt = `소아 영양 전문가로서, ${childAgeMonths}개월 아이의 오늘 영양 달성률을 보고 보호자에게 한국어로 핵심만 담아 1문장으로 조언해 주세요.

달성률: ${Object.entries(achievement).map(([k, v]) => `${nutrientKr[k] ?? k} ${v.toFixed(0)}%`).join(', ')}
${deficientList ? `특히 부족한 영양소: ${deficientList}` : '전반적으로 양호합니다'}
${aiEstimatedFoods.length > 0 ? `(AI 추정 음식 포함: ${aiEstimatedFoods.join(', ')})` : ''}`

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${GEMINI_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.7, maxOutputTokens: 512 }
        })
      }
    )
    const geminiData = await geminiRes.json()
    console.log('[Gemini] HTTP Status:', geminiRes.status)
    console.log('[Gemini] Response:', JSON.stringify(geminiData).slice(0, 600))
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    const aiComment = rawText.trim()

    // 응답
    return new Response(
      JSON.stringify({ nutrients: totalIntake, achievement, aiComment, aiEstimatedFoods }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    console.error('analyze-basic error: ', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})