// Supabase가 시간대 표시 없이 "YYYY-MM-DD HH:mm:ss" 형태로 줄 때도
// 항상 UTC로 해석해서 한국 시간(KST)으로 정확히 변환합니다.
export function formatKDate(value: string) {
  if (!value) return ''

  let iso = value.includes('T') ? value : value.replace(' ', 'T')

  const hasZone = /[Zz]$|[+-]\d\d:?\d\d$/.test(iso)
  if (!hasZone) {
    iso = `${iso}Z`
  }

  return new Date(iso).toLocaleDateString('ko-KR', { timeZone: 'Asia/Seoul' })
}
