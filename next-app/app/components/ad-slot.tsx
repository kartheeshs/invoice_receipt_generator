'use client';

import type { ReactNode } from 'react';

export type AdSlotOrientation = 'horizontal' | 'vertical';

export type AdSlotProps = {
  label: string;
  description?: string;
  orientation?: AdSlotOrientation;
  className?: string;
  children?: ReactNode;
};

export default function AdSlot({
  label,
  description,
  orientation = 'horizontal',
  className,
  children,
}: AdSlotProps) {
  const classes = ['ad-slot', `ad-slot--${orientation}`];
  if (className) {
    classes.push(className);
  }

  return (
    <aside className={classes.join(' ')} role="complementary" aria-label={label}>
      <div className="ad-slot__badge" aria-hidden="true">
        <span>Ad space</span>
      </div>
      <div className="ad-slot__content">
        <strong className="ad-slot__label">{label}</strong>
        {description ? <p className="ad-slot__description">{description}</p> : null}
        {children}
      </div>
    </aside>
  );
}
