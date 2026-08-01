"use server";

import { revalidatePath } from "next/cache";
import { supabase } from "@/lib/supabase";

export async function addNotice(formData: FormData) {
  const { error } = await supabase.from("notices").insert({
    title: formData.get("title"),
    content: formData.get("content"),
    author: formData.get("author"),
  });

  if (error) {
    console.error("저장 오류:", error);
  }

  revalidatePath("/notices");
  revalidatePath("/");
}

export async function deleteNotice(id: number) {
  const { error } = await supabase
    .from("notices")
    .delete()
    .eq("id", id);

  if (error) {
    console.error("삭제 오류:", error);
  }

  revalidatePath("/notices");
  revalidatePath("/");
}
