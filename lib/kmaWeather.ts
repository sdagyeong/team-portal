// 기상청 항공기상청 API Hub - METAR / TAF / 공항경보 조회
// https://apihub.kma.go.kr 에서 발급받은 authKey를 .env.local (그리고 Vercel 환경변수)에
// KMA_AUTH_KEY 로 등록하세요.

export type AirportMetar = {
  code: string
  icao: string
  name: string
  tempC: number | null
  dewpointC: number | null
  qnhHpa: number | null
  windDirDeg: number | null
  windSpeedKt: number | null
  cavok: boolean
  observedAt: string | null
}

export type AirportTaf = {
  code: string
  icao: string
  name: string
  validFrom: string | null
  validTo: string | null
  windDirDeg: number | null
  windSpeedKt: number | null
  gustKt: number | null
  cavok: boolean
  maxTempC: number | null
  minTempC: number | null
}

export type AirportWarning = {
  icao: string
  airportName: string
  wrngMsg: string
  validTm1: string | null
  validTm2: string | null
}

const AIRPORTS: { code: string; icao: string; name: string }[] = [
  { code: 'ICN', icao: 'RKSI', name: '인천' },
  { code: 'GMP', icao: 'RKSS', name: '김포' },
  { code: 'CJU', icao: 'RKPC', name: '제주' },
  { code: 'PUS', icao: 'RKPK', name: '김해' },
  { code: 'TAE', icao: 'RKTN', name: '대구' },
  { code: 'CJJ', icao: 'RKTU', name: '청주' },
  { code: 'KWJ', icao: 'RKJJ', name: '광주' },
]

function extractTag(xml: string, tag: string): string | null {
  const re = new RegExp(`<iwxxm:${tag}[^>]*>([^<]*)<`, 'i')
  const m = xml.match(re)
  return m ? m[1].trim() : null
}

function extractItemTag(item: string, tag: string): string | null {
  const re = new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`, 'i')
  const m = item.match(re)
  return m ? m[1].trim() : null
}

function decodeXmlEntities(s: string): string {
  return s
    .replace(/&#xD;/gi, '\r')
    .replace(/&#13;/g, '\r')
    .replace(/&#xA;/gi, '\n')
    .replace(/&#10;/g, '\n')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
}

// ---------------- METAR ----------------

async function fetchMetar(icao: string): Promise<Omit<AirportMetar, 'code' | 'icao' | 'name'> | null> {
  const key = process.env.KMA_AUTH_KEY
  if (!key) return null

  const url =
    `https://apihub.kma.go.kr/api/typ02/openApi/AmmIwxxmService/getMetar` +
    `?pageNo=1&numOfRows=1&dataType=XML&icao=${icao}&authKey=${key}`

  try {
    const res = await fetch(url, { next: { revalidate: 600 } })
    const xml = await res.text()

    const temp = extractTag(xml, 'airTemperature')
    const dewpoint = extractTag(xml, 'dewpointTemperature')
    const qnh = extractTag(xml, 'qnh')
    const windDir = extractTag(xml, 'meanWindDirection')
    const windSpeed = extractTag(xml, 'meanWindSpeed')
    const cavok = /cloudAndVisibilityOK="true"/.test(xml)

    const obsMatch = xml.match(
      /<iwxxm:observationTime>[\s\S]*?<gml:timePosition>([^<]+)<\/gml:timePosition>/
    )

    return {
      tempC: temp !== null ? Number(temp) : null,
      dewpointC: dewpoint !== null ? Number(dewpoint) : null,
      qnhHpa: qnh !== null ? Number(qnh) : null,
      windDirDeg: windDir !== null ? Number(windDir) : null,
      windSpeedKt: windSpeed !== null ? Number(windSpeed) : null,
      cavok,
      observedAt: obsMatch ? obsMatch[1] : null,
    }
  } catch (e) {
    console.error('METAR 조회 오류:', icao, e)
    return null
  }
}

export async function getAllAirportMetar(): Promise<AirportMetar[]> {
  return Promise.all(
    AIRPORTS.map(async (a) => {
      const data = await fetchMetar(a.icao)
      return {
        code: a.code,
        icao: a.icao,
        name: a.name,
        tempC: data?.tempC ?? null,
        dewpointC: data?.dewpointC ?? null,
        qnhHpa: data?.qnhHpa ?? null,
        windDirDeg: data?.windDirDeg ?? null,
        windSpeedKt: data?.windSpeedKt ?? null,
        cavok: data?.cavok ?? false,
        observedAt: data?.observedAt ?? null,
      }
    })
  )
}

// ---------------- TAF ----------------

async function fetchTaf(icao: string): Promise<Omit<AirportTaf, 'code' | 'icao' | 'name'> | null> {
  const key = process.env.KMA_AUTH_KEY
  if (!key) return null

  const url =
    `https://apihub.kma.go.kr/api/typ02/openApi/AmmIwxxmService/getTaf` +
    `?pageNo=1&numOfRows=1&dataType=XML&icao=${icao}&authKey=${key}`

  try {
    const res = await fetch(url, { next: { revalidate: 1800 } })
    const xml = await res.text()

    const validFromMatch = xml.match(
      /<iwxxm:validPeriod>[\s\S]*?<gml:beginPosition>([^<]+)<\/gml:beginPosition>/
    )
    const validToMatch = xml.match(
      /<iwxxm:validPeriod>[\s\S]*?<gml:endPosition>([^<]+)<\/gml:endPosition>/
    )
    const windDir = extractTag(xml, 'meanWindDirection')
    const windSpeed = extractTag(xml, 'meanWindSpeed')
    const gust = extractTag(xml, 'windGustSpeed')
    const cavok = /cloudAndVisibilityOK="true"/.test(xml)

    const maxTemps = [...xml.matchAll(/<iwxxm:maximumAirTemperature(?!Time)[^>]*>([^<]+)</g)].map((m) =>
      Number(m[1])
    )
    const minTemps = [...xml.matchAll(/<iwxxm:minimumAirTemperature(?!Time)[^>]*>([^<]+)</g)].map((m) =>
      Number(m[1])
    )

    return {
      validFrom: validFromMatch ? validFromMatch[1] : null,
      validTo: validToMatch ? validToMatch[1] : null,
      windDirDeg: windDir !== null ? Number(windDir) : null,
      windSpeedKt: windSpeed !== null ? Number(windSpeed) : null,
      gustKt: gust !== null ? Number(gust) : null,
      cavok,
      maxTempC: maxTemps.length ? Math.max(...maxTemps) : null,
      minTempC: minTemps.length ? Math.min(...minTemps) : null,
    }
  } catch (e) {
    console.error('TAF 조회 오류:', icao, e)
    return null
  }
}

export async function getAllAirportTaf(): Promise<AirportTaf[]> {
  return Promise.all(
    AIRPORTS.map(async (a) => {
      const data = await fetchTaf(a.icao)
      return {
        code: a.code,
        icao: a.icao,
        name: a.name,
        validFrom: data?.validFrom ?? null,
        validTo: data?.validTo ?? null,
        windDirDeg: data?.windDirDeg ?? null,
        windSpeedKt: data?.windSpeedKt ?? null,
        gustKt: data?.gustKt ?? null,
        cavok: data?.cavok ?? false,
        maxTempC: data?.maxTempC ?? null,
        minTempC: data?.minTempC ?? null,
      }
    })
  )
}

// ---------------- 공항경보 ----------------

export async function getAllWarnings(): Promise<AirportWarning[]> {
  const key = process.env.KMA_AUTH_KEY
  if (!key) return []

  const url =
    `https://apihub.kma.go.kr/api/typ02/openApi/AmmService/getWarning` +
    `?pageNo=1&numOfRows=50&dataType=XML&authKey=${key}`

  try {
    const res = await fetch(url, { next: { revalidate: 300 } })
    const xml = await res.text()
    const items = xml.match(/<item>[\s\S]*?<\/item>/g) ?? []
    const domesticIcaos = new Set(AIRPORTS.map((a) => a.icao))

    return items
      .map((item) => ({
        icao: extractItemTag(item, 'icaoCode') ?? '',
        airportName: extractItemTag(item, 'airportName') ?? '',
        wrngMsg: (extractItemTag(item, 'wrngMsg') ?? '')
          .replace(/&#xD;/g, '')
          .replace(/\r\n/g, '\n')
          .replace(/\r/g, '\n')
          .trim(),
        validTm1: extractItemTag(item, 'validTm1'),
        validTm2: extractItemTag(item, 'validTm2'),
      }))
      .filter((w) => domesticIcaos.has(w.icao))
  } catch (e) {
    console.error('공항경보 조회 오류:', e)
    return []
  }
}
