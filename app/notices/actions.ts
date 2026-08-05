"use server";

import { revalidatePath } from "next/cache";
import { supabase } from "@/lib/supabase";

export async function addNotice(formData: FormData) {
  const title = formData.get("title") as string;
  const content = formData.get("content") as string;
  const author = formData.get("author") as string;
  const file = formData.get("file") as File | null;

  let file_url: string | null = null;
  let file_name: string | null = null;

  if (file && file.size > 0) {
    const filePath = `${Date.now()}_${file.name}`;

    const { error: uploadError } = await supabase.storage
      .from("task-documents")
      .upload(filePath, file);

    if (uploadError) {
      console.error("파일 업로드 오류:", uploadError);
    } else {
      const { data: publicUrlData } = supabase.storage
        .from("task-documents")
        .getPublicUrl(filePath);
      file_url = publicUrlData.publicUrl;
      file_name = file.name;
    }
  }

  const { error } = await supabase.from("notices").insert({
    title,
    content,
    author,
    file_url,
    file_name,
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
