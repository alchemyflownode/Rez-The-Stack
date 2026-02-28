import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "@/styles/dual-theme.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sovereign AI",
  description: "Builder Mode • Flow Mode",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
