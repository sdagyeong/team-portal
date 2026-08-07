"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { searchAll, SEARCH_CATEGORIES, type SearchResult } from "@/app/searchActions";
import { IconFilePreview } from "./icons";

export default function SearchBox() {
  const [category, setCategory] = useState<string>("전체");
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const boxRef = useRef<HTMLDivElement>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  function runSearch(value: string, cat: string) {
    if (timerRef.current) clearTimeout(timerRef.current);

    if (!value.trim()) {
      setResults([]);
      setOpen(false);
      return;
    }

    timerRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await searchAll(value, cat);
        setResults(res);
        setOpen(true);
      } finally {
        setLoading(false);
      }
    }, 300);
  }

  function handleQueryChange(value: string) {
    setQuery(value);
    runSearch(value, category);
  }

  function handleCategoryChange(value: string) {
    setCategory(value);
    if (query.trim()) runSearch(query, value);
  }

  function goFullSearch() {
    if (!query.trim()) return;
    setOpen(false);
    router.push(`/search?q=${encodeURIComponent(query)}&type=${encodeURIComponent(category)}`);
  }

  function goResult(href: string) {
    setOpen(false);
    setQuery("");
    router.push(href);
  }

  return (
    <div className="header-search-wrap" ref={boxRef}>
      <form
        className="header-search"
        onSubmit={(e) => {
          e.preventDefault();
          goFullSearch();
        }}
      >
        <select
          className="header-search-category"
          value={category}
          onChange={(e) => handleCategoryChange(e.target.value)}
        >
          {SEARCH_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>

        <input
          type="text"
          placeholder="검색어 입력..."
          value={query}
          onChange={(e) => handleQueryChange(e.target.value)}
          onFocus={() => query.trim() && setOpen(true)}
        />

        <button type="submit" aria-label="검색">
          <IconFilePreview size={16} />
        </button>
      </form>

      {open && (
        <div className="search-dropdown">
          {loading && <p className="search-dropdown-empty">검색 중...</p>}

          {!loading && results.length === 0 && (
            <p className="search-dropdown-empty">일치하는 결과가 없습니다.</p>
          )}

          {!loading &&
            results.map((r) => (
              <button
                key={`${r.type}-${r.id}`}
                type="button"
                className="search-dropdown-item"
                onClick={() => goResult(r.href)}
              >
                <span className="search-dropdown-type">{r.type}</span>
                <span className="search-dropdown-title">{r.title}</span>
                <span className="search-dropdown-author">{r.author}</span>
              </button>
            ))}

          {!loading && (
            <button type="button" className="search-dropdown-more" onClick={goFullSearch}>
              &quot;{query}&quot; 전체 검색결과 보기
            </button>
          )}
        </div>
      )}
    </div>
  );
}
