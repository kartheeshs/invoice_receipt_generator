'use client';

import { languageOptions, useTranslation } from '../../lib/i18n';

export default function LanguageSwitcher({ variant = 'inline' }: { variant?: 'inline' | 'compact' }) {
  const { language, setLanguage, t } = useTranslation();
  const label = t('language.select', 'Select language');

  return (
    <label className={`language-switcher language-switcher--${variant}`}>
      <span className="sr-only">{label}</span>
      <select
        value={language}
        onChange={(event) => setLanguage(event.target.value as typeof language)}
        className="language-switcher__select"
        aria-label={label}
      >
        {languageOptions.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}
