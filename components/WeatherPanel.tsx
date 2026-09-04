'use client'

import type { AirportMetar, AirportTaf, AirportWarning } from '@/lib/kmaWeather'

function fmtDdhhmm(iso: string | null) {
  if (!iso) return '------KST'
  try {
    const d = new Date(iso)
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: 'Asia/Seoul',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).formatToParts(d)
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '00'
    return `${get('day')}${get('hour')}${get('minute')}KST`
  } catch {
    return '------KST'
  }
}

function fmtWarnTime(v: string | null) {
  if (!v || v.length < 12) return '------KST'
  return `${v.slice(6, 8)}${v.slice(8, 10)}${v.slice(10, 12)}KST`
}

function fmtTemp(v: number | null) {
  if (v === null) return '--'
  const r = Math.round(v)
  return r < 0 ? `M${String(Math.abs(r)).padStart(2, '0')}` : String(r).padStart(2, '0')
}

function fmtWind(dir: number | null, speed: number | null, gust?: number | null) {
  if (dir === null || speed === null) return '-----KT'
  const g = gust ? `G${String(gust).padStart(2, '0')}` : ''
  return `${String(dir).padStart(3, '0')}${String(speed).padStart(2, '0')}${g}KT`
}

function fmtQnh(v: number | null) {
  if (v === null) return 'Q----'
  return `Q${Math.round(v).toString().padStart(4, '0')}`
}

function metarSummary(m?: AirportMetar) {
  if (!m) return '자료 없음'
  const time = fmtDdhhmm(m.observedAt)
  const wind = fmtWind(m.windDirDeg, m.windSpeedKt)
  const cavok = m.cavok ? 'CAVOK' : '-'
  const temp = `${fmtTemp(m.tempC)}/${fmtTemp(m.dewpointC)}`
  const qnh = fmtQnh(m.qnhHpa)
  return `${time} ${wind} ${cavok} ${temp} ${qnh}`
}

function tafSummary(t?: AirportTaf) {
  if (!t) return '자료 없음'
  const period = `${fmtDdhhmm(t.validFrom)} ~ ${fmtDdhhmm(t.validTo)}`
  const wind = fmtWind(t.windDirDeg, t.windSpeedKt, t.gustKt)
  const cavok = t.cavok ? 'CAVOK' : '-'
  const temp = `${fmtTemp(t.maxTempC)}/${fmtTemp(t.minTempC)}`
  return `${period} ${wind} ${cavok} ${temp}`
}

export default function WeatherPanel({
  metarList,
  tafList,
  warnings,
}: {
  metarList: AirportMetar[]
  tafList: AirportTaf[]
  warnings: AirportWarning[]
}) {
  return (
    <div className="weather-airport-list">
      {metarList.map((m) => {
        const t = tafList.find((x) => x.code === m.code)
        const w = warnings.filter((x) => x.icao === m.icao)

        return (
          <div key={m.code} className="weather-airport-block">
            <h4 className="weather-airport-title">{m.code}</h4>
            <table className="weather-airport-table">
              <thead>
                <tr>
                  <th>구분</th>
                  <th>내용</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>METAR</td>
                  <td>{metarSummary(m)}</td>
                </tr>
                <tr>
                  <td>TAF</td>
                  <td>{tafSummary(t)}</td>
                </tr>
                <tr>
                  <td>특보</td>
                  <td>
                    {w.length === 0
                      ? '해당 사항 없음'
                      : w.map((item, i) => (
                          <div key={i} className="weather-warning-line">
                            {fmtWarnTime(item.validTm1)} ~ {fmtWarnTime(item.validTm2)}{' '}
                            {item.wrngMsg.split('\n')[0]}
                          </div>
                        ))}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        )
      })}
    </div>
  )
}
