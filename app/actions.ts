"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { supabase } from "@/lib/supabase";


export async function addNotice(formData: FormData) {

  const { error } = await supabase
    .from("notices")
    .insert({
      title: formData.get("title"),
      content: formData.get("content"),
      author: formData.get("author"),
    });


  console.log("저장 오류:", error);

  revalidatePath("/");
}



export async function deleteNotice(id: number) {
  const { data, error } = await supabase
    .from("notices")
    .delete()
    .eq("id", id)
    .select();

  console.log("삭제 결과:", data);
  console.log("삭제 오류:", error);

  revalidatePath("/");
}