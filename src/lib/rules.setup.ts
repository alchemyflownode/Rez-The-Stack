import { Governor } from './delta-zero-engine';

// TEXT RULES
Governor.addRule("text", {
  name: "No_Hallucination_Apology",
  verify: (txt: string) => !txt.toLowerCase().includes("i don't know"),
  correct: (txt: string) => txt.replace(/i don't know/gi, "Further analysis is required")
});

// CODE RULES
Governor.addRule("code", {
  name: "No_Dangerous_Ops",
  verify: (code: string) => !code.includes("rm -rf"),
  correct: (code: string) => code.replace(/rm -rf/g, "echo 'Blocked'")
});

console.log("✅ Governor Rules Loaded.");
