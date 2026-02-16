import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "RezStack Sovereign IDE - Your Code. Your Models. Your Sovereignty.",
  description: "A local-first, constitutional AI development environment with 25+ local models, GPU acceleration, zero telemetry, and self-learning memory crystals.",
  keywords: [
    "RezStack",
    "Sovereign IDE",
    "Local AI",
    "Constitutional AI",
    "GPU Development",
    "Ollama",
    "Next.js",
    "TypeScript",
    "Self-hosted AI",
    "Code Sovereignty"
  ],
  authors: [{ name: "RezStack Contributors" }],
  icons: {
    icon: "/favicon.ico",
  },
  openGraph: {
    title: "RezStack Sovereign IDE",
    description: "Your code. Your models. Your sovereignty.",
    url: "https://github.com/alchemyflownode/Rez-The-Stack",
    siteName: "RezStack",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "RezStack Sovereign IDE",
    description: "Your code. Your models. Your sovereignty.",
  },
};
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground`}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
