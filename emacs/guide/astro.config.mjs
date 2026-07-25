import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [
    starlight({
      title: 'Emacs JVM 가이드',
      defaultLocale: 'root',
      locales: {
        root: { label: '한국어', lang: 'ko' },
      },
      sidebar: [
        {
          label: '시작하기',
          items: [
            { label: '이 가이드에 대해', slug: 'index' },
            { label: '설치와 준비물', slug: 'setup' },
            { label: '키 표기법과 기본기', slug: 'basics' },
          ],
        },
        {
          label: '시나리오',
          items: [
            { label: '프로젝트 열고 코드 탐색', slug: 'scenarios/explore' },
            { label: '코드 수정하기', slug: 'scenarios/edit' },
            { label: '테스트 실행하기', slug: 'scenarios/test' },
            { label: '디버깅하기', slug: 'scenarios/debug' },
            { label: 'Spring Boot 실행', slug: 'scenarios/spring-boot' },
            { label: 'Git 커밋과 PR', slug: 'scenarios/git-pr' },
          ],
        },
        {
          label: '레퍼런스',
          items: [
            { label: '전체 키맵', slug: 'reference/keymap' },
            { label: '학습 로드맵', slug: 'reference/roadmap' },
            { label: '트러블슈팅', slug: 'reference/troubleshooting' },
          ],
        },
      ],
    }),
  ],
});
