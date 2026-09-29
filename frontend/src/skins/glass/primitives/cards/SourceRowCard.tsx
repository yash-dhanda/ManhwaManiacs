"use client";

import { useState } from "react";
import { Badge } from "../Badge";
import { Cover } from "../Cover";
import { IconButton } from "../IconButton";
import { CardBase } from "./CardBase";
import { HealthBead, type Health } from "./HealthBead";
import { SourceMonogram } from "./SourceMonogram";

export interface SourceRowCardProps {
  id: string;
  name: string;
  description: string;
  iconUrl?: string;
  language?: string;
  health: Health;
  demoted?: boolean;
  mature?: boolean;
  pinned: boolean;
  onPin: () => void;
  onOpen: () => void;
  disabled?: boolean;
  disabledReason?: string;
}

/** A 64 tall row: a 44 px source logo (radius 10) or the monogram fallback, the name `headline` + a health bead, the language tag, the description in 1 line, an 18+ tag when mature, the pin toggle. */
export function SourceRowCard({ id, name, description, iconUrl, language, health, demoted, mature, pinned, onPin, onOpen, disabled, disabledReason }: SourceRowCardProps) {
  const [broken, setBroken] = useState(false);
  return (
    <CardBase label={`${name}, ${health === "ok" ? "working" : health}`} onPress={onOpen} slab="bare" sink={0.99} disabled={disabled} disabledReason={disabledReason} className="g-sourcerow">
      <span className="g-sourcerow__logo">{iconUrl && !broken ? <Cover src={iconUrl} width={44} height={44} onError={() => setBroken(true)} /> : <SourceMonogram id={id} name={name} />}</span>
      <div className="g-sourcerow__text">
        <div className="g-sourcerow__name"><span className="type-headline">{name}</span><HealthBead health={health} demoted={demoted} />{language ? <span className="type-caption1 g-sourcerow__lang">{language.toUpperCase()}</span> : null}{mature ? <Badge kind="mature" /> : null}</div>
        <p className="type-footnote g-sourcerow__desc">{description}</p>
      </div>
      <IconButton variant="plain" icon="push-pin" label="Pin source" pressed={pinned} onPress={onPin} />
    </CardBase>
  );
}
