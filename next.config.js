/** @type {import('next').NextConfig} */
/* eslint-disable @typescript-eslint/no-var-requires */
const nextConfig = {
  output: process.env.NODE_ENV === 'production' ? 'export' : 'standalone',
  trailingSlash: true,
  eslint: {
    dirs: ['src'],
  },

  reactStrictMode: false,
  swcMinify: true,
  
  // Disable server-side features for static export
  ...(process.env.NODE_ENV === 'production' && {
    distDir: 'out',
  }),

  // Uncoment to add domain whitelist
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: '**',
      },
    ],
  },

  webpack(config) {
    // Grab the existing rule that handles SVG imports
    const fileLoaderRule = config.module.rules.find((rule) =>
      rule.test?.test?.('.svg')
    );

    config.module.rules.push(
      // Reapply the existing rule, but only for svg imports ending in ?url
      {
        ...fileLoaderRule,
        test: /\.svg$/i,
        resourceQuery: /url/, // *.svg?url
      },
      // Convert all other *.svg imports to React components
      {
        test: /\.svg$/i,
        issuer: { not: /\.(css|scss|sass)$/ },
        resourceQuery: { not: /url/ }, // exclude if *.svg?url
        loader: '@svgr/webpack',
        options: {
          dimensions: false,
          titleProp: true,
        },
      }
    );

    // Modify the file loader rule to ignore *.svg, since we have it handled now.
    fileLoaderRule.exclude = /\.svg$/i;

    config.resolve.fallback = {
      ...config.resolve.fallback,
      net: false,
      tls: false,
      crypto: false,
    };

    return config;
  },
};

const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
  // Optimize for shared hosting
  maximumFileSizeToCacheInBytes: 5000000, // 5MB limit
  runtimeCaching: [
    {
      urlPattern: /^https?.*/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'offlineCache',
        expiration: {
          maxEntries: 200,
          maxAgeSeconds: 86400, // 24 hours
        },
      },
    },
  ],
});

// Additional optimizations for static export
if (process.env.NODE_ENV === 'production') {
  nextConfig.experimental = {
    ...nextConfig.experimental,
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', '@heroicons/react'],
  };
  
  // Disable features that don't work with static export
  nextConfig.images = {
    ...nextConfig.images,
    unoptimized: true,
  };
}

module.exports = withPWA(nextConfig);
