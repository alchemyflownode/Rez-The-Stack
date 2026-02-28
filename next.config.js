/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**' },
    ],
  },
  // ServerActions are default in Next.js 15+. No need to enable.
  // Removing the experimental block fixes the boolean error.
}

module.exports = nextConfig
