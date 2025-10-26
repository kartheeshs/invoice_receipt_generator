/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: {
    typedRoutes: true,
  },
  async rewrites() {
    return [
      {
        source: '/app',
        destination: '/flutter-app/index.html',
      },
      {
        source: '/app/:path*',
        destination: '/flutter-app/:path*',
      },
    ];
  },
};

export default nextConfig;
