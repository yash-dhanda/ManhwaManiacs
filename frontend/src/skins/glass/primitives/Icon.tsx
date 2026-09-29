import {
  ArrowClockwiseIcon, ArrowSquareOutIcon, BellIcon, BellRingingIcon, BookOpenIcon, BookmarkSimpleIcon, CaretDownIcon,
  CaretLeftIcon, CaretRightIcon, CatIcon, CheckCircleIcon, CheckIcon, CloudArrowDownIcon, CoffeeIcon, DotsThreeIcon,
  EyeIcon, EyeSlashIcon, FlameIcon, GhostIcon, GlobeIcon, HeartIcon, ImageBrokenIcon, MagicWandIcon,
  MagnifyingGlassIcon, MoonIcon, PlayIcon, PlusIcon, PushPinIcon, RocketLaunchIcon, SparkleIcon, StarIcon,
  SwordIcon, TrashSimpleIcon, WarningCircleIcon, WarningIcon, WifiSlashIcon, XIcon, BookOpenTextIcon, ArrowLeftIcon, ArrowRightIcon, ExportIcon,
} from "@phosphor-icons/react/ssr";
import type { ComponentType } from "react";
import { AgeGate, Droplet, StripScroll } from "../icons/glyphs.generated";

/**
 * TODO(web/01): stand-in for the shared Glass `Icon` (web/01 is not integrated yet). Same shape: a name, a
 * size and a weight. When web/01 lands, replace this file's body with a re-export.
 */
export type IconWeight = "regular" | "duotone" | "fill" | "light";
type PhProps = { size?: number | string; weight?: IconWeight; color?: string; className?: string; "aria-hidden"?: boolean };

const PH = {
  "arrow-clockwise": ArrowClockwiseIcon, "arrow-square-out": ArrowSquareOutIcon, bell: BellIcon, "bell-ringing": BellRingingIcon,
  "book-open": BookOpenIcon, "book-open-text": BookOpenTextIcon, "bookmark-simple": BookmarkSimpleIcon, "caret-down": CaretDownIcon, "caret-left": CaretLeftIcon,
  "caret-right": CaretRightIcon, cat: CatIcon, "check-circle": CheckCircleIcon, check: CheckIcon, "cloud-arrow-down": CloudArrowDownIcon,
  coffee: CoffeeIcon, "dots-three": DotsThreeIcon, eye: EyeIcon, "eye-slash": EyeSlashIcon, flame: FlameIcon, ghost: GhostIcon,
  globe: GlobeIcon, heart: HeartIcon, "image-broken": ImageBrokenIcon, "magic-wand": MagicWandIcon, "magnifying-glass": MagnifyingGlassIcon,
  moon: MoonIcon, play: PlayIcon, plus: PlusIcon, "push-pin": PushPinIcon, "rocket-launch": RocketLaunchIcon, sparkle: SparkleIcon,
  star: StarIcon, sword: SwordIcon, trash: TrashSimpleIcon, "warning-circle": WarningCircleIcon, warning: WarningIcon,
  "wifi-slash": WifiSlashIcon, x: XIcon, share: ExportIcon, "arrow-left": ArrowLeftIcon, "arrow-right": ArrowRightIcon,
} as const satisfies Record<string, ComponentType<PhProps>>;

const GL = { droplet: Droplet, "age-gate": AgeGate, "strip-scroll": StripScroll } as const;

export type IconName = keyof typeof PH | keyof typeof GL;

export function Icon({ name, size = 22, weight = "regular", color, className }: { name: IconName; size?: number; weight?: IconWeight; color?: string; className?: string }) {
  if (name in GL) {
    const G = GL[name as keyof typeof GL];
    return <G size={size} weight={weight === "light" ? "regular" : weight} color={color} className={className} aria-hidden />;
  }
  const P = PH[name as keyof typeof PH] as ComponentType<PhProps>;
  return <P size={size} weight={weight} color={color} className={className} aria-hidden />;
}
