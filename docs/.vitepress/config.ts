import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Dotfiles',
  description: 'Cross-platform dotfiles — one command, any platform, a complete modern dev environment.',
  base: '/dotfiles/',
  cleanUrls: true,
  lastUpdated: true,

  head: [
    ['meta', { name: 'theme-color', content: '#3b82f6' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'kariha70/dotfiles' }],
    ['meta', { property: 'og:description', content: 'Cross-platform dotfiles with 30+ modern CLI tools, SHA256-verified downloads, and CI-tested bootstrap.' }],
  ],

  themeConfig: {
    logo: '🏠',
    siteTitle: 'Dotfiles',

    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Reference', link: '/reference/tools' },
      { text: 'Contributing', link: '/contributing' },
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'Platform Details', link: '/guide/platforms' },
          { text: 'Configuration', link: '/guide/configuration' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Tools & Runtimes', link: '/reference/tools' },
          { text: 'Aliases & Key Bindings', link: '/reference/aliases' },
          { text: 'Security & Integrity', link: '/reference/security' },
        ],
      },
      {
        text: 'Project',
        items: [
          { text: 'Contributing', link: '/contributing' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/kariha70/dotfiles' },
    ],

    editLink: {
      pattern: 'https://github.com/kariha70/dotfiles/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 Kari Michael Hagemeier',
    },

    search: {
      provider: 'local',
    },
  },
})
