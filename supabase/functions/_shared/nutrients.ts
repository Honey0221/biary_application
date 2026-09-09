// 영양소 코드 목록
export const NUTRIENT_CODES = [
  'energy', 'carbohydrate', 'protein', 'fat',
  'sugar', 'dietary_fiber', 'sodium', 'calcium',
  'iron', 'zinc', 'vitamin_a', 'vitamin_c', 'vitamin_d'
]

// DRI 달성률 계산
export function calcAchievement(
  intake: Record<string, number>,
  driMap: Record<string, number | null>,
  ageMonths: number
): Record<string, number> {
  const achievement: Record<string, number> = {};

  for (const code of NUTRIENT_CODES) {
    const consumed = intake[code]
    if (consumed == null) continue

    // 당류: 3세(36개월) 이상 에너지 비율 기반 (목표 20%)
    if (code === 'sugar' && ageMonths >= 36) {
      const energy = intake['energy']
      if (energy && energy > 0) {
        const ratio = (consumed * 4) / energy * 100
        achievement[code] = Math.min(ratio / 20.0 * 100, 999.9)
      }
      continue
    }

    const recommended = driMap[code]
    if (!recommended || recommended <= 0) continue
    achievement[code] = Math.min(consumed / recommended * 100, 999.9)
  }

  return achievement
}

// 연령 구간 코드 결정
export function resolveAgeGroupCode(ageMonths: number, gender: string): string {
  if (ageMonths < 6) return '0_5m'
  if (ageMonths < 12) return '6_11m'
  if (ageMonths < 36) return '1_2y'
  if (ageMonths < 72) return '3_5y'
  return `6_8y_${gender}`
}

// 식품처 API 직접 검색
export async function searchFoodApi(
  name: string,
  apikey: string
): Promise<Record<string, number | null> | null> {
  try {
    const url = new URL(
      'https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02/getFoodNtrCpntDblnq02'
    )
    url.searchParams.set('serviceKey', apikey)
    url.searchParams.set('pageNo', '1')
    url.searchParams.set('numOfRows', '3')
    url.searchParams.set('type', 'json')
    url.searchParams.set('FOOD_NM_KR', name)

    const res = await fetch(url.toString())
    if (!res.ok) return null
    
    const json = await res.json()
    const rawItems = json?.body?.items
    if (!rawItems) return null

    const item = Array.isArray(rawItems) ? rawItems[0] : rawItems

    const AMT_MAP: Record<string, string> = {
      energy: 'AMT_NUM1', protein: 'AMT_NUM3', fat: 'AMT_NUM4',
      carbohydrate: 'AMT_NUM6', sugar: 'AMT_NUM7', dietary_fiber: 'AMT_NUM8',
      calcium: 'AMT_NUM9', iron: 'AMT_NUM10', sodium: 'AMT_NUM13',
      vitamin_a: 'AMT_NUM14', vitamin_c: 'AMT_NUM21', vitamin_d: 'AMT_NUM22',
      zinc: 'AMT_NUM116'
    }
    const nutrients: Record<string, number | null> = {}
    for (const [code, amtKey] of Object.entries(AMT_MAP)) {
      const v = parseFloat(item[amtKey])
      nutrients[code] = isNaN(v) ? null : v
    }
    return nutrients
  } catch {
    return null
  }
}

// Gemini Flash로 영양소 추정 (직접 음식 입력 중 식품처 DB 미매칭 시)
export async function estimateByGemini(
  foodName: string,
  geminiKey: string
): Promise<Record<string, number | null>> {
  const prompt = `음식명: "${foodName}"
  위 음식의 100g 기준 영양소를 JSON으로 반환하세요.
  반드시 아래 키만 포함하고, 모르는 값은 null로 설정하세요:
  {"nutrients": {
    "energy": (kcal),
    "carbohydrate": (g),
    "protein": (g),
    "fat": (g),
    "sugar": (g),
    "dietary_fiber": (g),
    "sodium": (mg),
    "calcium": (mg),
    "iron": (mg),
    "zinc": (mg),
    "vitamin_a": (μg),
    "vitamin_c": (mg),
    "vitamin_d": (μg)
  }}
  JSON만 반환하세요. 설명 없이.`
  
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${geminiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ 
              text: '반드시 한국어로만 답변하세요. You must respond in Korean only.' 
            }]
          },
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 300 }
        })
      }
    )

    const data = await res.json()
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}'
    const cleaned = raw.replace(/```json\n?|\n?```/g, '').trim()
    return JSON.parse(cleaned)
  } catch {
    return {}
  }
}