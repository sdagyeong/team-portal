"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { IconPin, IconFolder, IconPlane, IconContact } from "./icons";

const menuItems = [
  { href: "/notices", label: "업무지시공유", Icon: IconPin },
  { href: "/resources", label: "자료실", Icon: IconFolder },
  { href: "/tasks", label: "AIRPORT", Icon: IconPlane },
  { href: "/contacts", label: "계정/연락망", Icon: IconContact },
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
              <span className="menu-icon">
                <item.Icon size={16} />
              </span>
              {item.label}
            </div>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
