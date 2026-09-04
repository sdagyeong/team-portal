// 작성된 지 24시간 이내면 true (NEW 배지 표시 여부 판단)
export function isNew(createdAt: string | null | undefined, hours: number = 24): boolean {
  if (!createdAt) return false
  const created = new Date(createdAt).getTime()
  if (Number.isNaN(created)) return false
  return Date.now() - created < hours * 60 * 60 * 1000
}
