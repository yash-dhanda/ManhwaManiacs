import { redirect } from "next/navigation";

/** `setup` is a server redirect to `/login` on the web (cinematic §8.0.3, §15.10 S7). */
export default function SetupRedirect(): never {
  redirect("/login");
}
