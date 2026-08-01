"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const menuItems = [
  { href: "/notices", label: "업무지시공유", icon: "📌" },
  { href: "/resources", label: "자료실", icon: "📁" },
  { href: "/tasks", label: "업무관리", icon: "✅" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar">
      <Link href="/" className="brand-link">
        <div className="brand">
          <span className="brand-line1">JEJUAIR</span>
          <span className="brand-line2">RAMP CONTROL TEAM</span>
        </div>
      </Link>

      <nav>
        {menuItems.map((item) => (
          <Link key={item.href} href={item.href}>
            <div className={`menu ${pathname === item.href ? "active" : ""}`}>
              <span className="menu-icon">{item.icon}</span>
              {item.label}
            </div>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
