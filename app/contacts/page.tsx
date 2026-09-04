import { supabase } from '@/lib/supabaseClient'
import { isNew } from '@/lib/isNew'
import ContactsBoard from './ContactsBoard'
import { IconContact } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function ContactsPage() {
  const [{ data: systemAccounts, error: accError }, { data: phoneContacts, error: contactError }] =
    await Promise.all([
      supabase.from('system_accounts').select('*').order('id', { ascending: true }),
      supabase.from('phone_contacts').select('*').order('id', { ascending: true }),
    ])

  if (accError) console.error(accError)
  if (contactError) console.error(contactError)

  return (
    <div className="page">
      <h1>
        <IconContact size={20} className="page-title-icon" /> 계정/연락망
      </h1>

      <ContactsBoard
        systemAccounts={systemAccounts ?? []}
        phoneContacts={phoneContacts ?? []}
      />
    </div>
  )
}
