// PintaGroupFinder - Score Color Updater
//
// Fetches Raider.IO Mythic+ score tiers and updates PGF.SCORE_COLORS in src/Config.lua.

const CONFIG_PATH = "src/Config.lua";
const SCORE_TIER_URL = "https://raider.io/api/v1/mythic-plus/score-tiers";
const MIN_EXPECTED_SCORE_TIERS = 100;
const MIN_EXPECTED_TOP_SCORE = 3000;
const MAX_EXPECTED_BOTTOM_SCORE = 500;

type ScoreTier = {
  score: number;
  rgbFloat: [number, number, number];
};

type DiffSummary = {
  added: number;
  removed: number;
  changed: number;
  unchanged: number;
};

function isScoreTier(value: unknown): value is ScoreTier {
  if (!value || typeof value !== "object") {
    return false;
  }

  const candidate = value as Record<string, unknown>;
  return typeof candidate.score === "number"
    && Number.isFinite(candidate.score)
    && Array.isArray(candidate.rgbFloat)
    && candidate.rgbFloat.length === 3
    && candidate.rgbFloat.every((channel) => typeof channel === "number" && Number.isFinite(channel));
}

function extractScoreTiers(payload: unknown): ScoreTier[] {
  if (Array.isArray(payload) && payload.every(isScoreTier)) {
    return payload;
  }

  if (payload && typeof payload === "object") {
    const record = payload as Record<string, unknown>;
    const candidates = [record.scoreTiers, record.tiers, record.data];
    for (const candidate of candidates) {
      if (Array.isArray(candidate) && candidate.every(isScoreTier)) {
        return candidate;
      }
    }
  }

  throw new Error("Unexpected Raider.IO score tier payload shape.");
}

function validateScoreTiers(scoreTiers: ScoreTier[]): void {
  if (scoreTiers.length < MIN_EXPECTED_SCORE_TIERS) {
    throw new Error(
      `Refusing to update: expected at least ${MIN_EXPECTED_SCORE_TIERS} score tiers, got ${scoreTiers.length}.`,
    );
  }

  const seenScores = new Set<number>();
  for (let index = 0; index < scoreTiers.length; index += 1) {
    const { score, rgbFloat } = scoreTiers[index];

    if (!Number.isInteger(score) || score < 0) {
      throw new Error(`Invalid score at row ${index + 1}: ${score}`);
    }

    if (seenScores.has(score)) {
      throw new Error(`Duplicate score tier detected: ${score}`);
    }
    seenScores.add(score);

    if (index > 0 && scoreTiers[index - 1].score <= score) {
      throw new Error(
        `Score tiers are not strictly descending at row ${index + 1}: ${scoreTiers[index - 1].score} then ${score}`,
      );
    }

    rgbFloat.forEach((channel, channelIndex) => {
      if (channel < 0 || channel > 1) {
        throw new Error(
          `RGB channel out of range at row ${index + 1}, channel ${channelIndex + 1}: ${channel}`,
        );
      }
    });
  }

  const topScore = scoreTiers[0]?.score ?? 0;
  const bottomScore = scoreTiers.at(-1)?.score ?? 0;

  if (topScore < MIN_EXPECTED_TOP_SCORE) {
    throw new Error(
      `Top score tier looks suspiciously low: expected >= ${MIN_EXPECTED_TOP_SCORE}, got ${topScore}.`,
    );
  }

  if (bottomScore > MAX_EXPECTED_BOTTOM_SCORE) {
    throw new Error(
      `Bottom score tier looks suspiciously high: expected <= ${MAX_EXPECTED_BOTTOM_SCORE}, got ${bottomScore}.`,
    );
  }
}

function formatChannel(channel: number): string {
  return channel.toFixed(2);
}

function formatScoreTier(scoreTier: ScoreTier): string {
  const [red, green, blue] = scoreTier.rgbFloat;
  return `${scoreTier.score}:[${formatChannel(red)},${formatChannel(green)},${formatChannel(blue)}]`;
}

function formatScoreTierPreview(scoreTiers: ScoreTier[]): string {
  if (scoreTiers.length <= 6) {
    return scoreTiers.map(formatScoreTier).join(" ");
  }

  const head = scoreTiers.slice(0, 3).map(formatScoreTier).join(" ");
  const tail = scoreTiers.slice(-3).map(formatScoreTier).join(" ");
  return `${head} ... ${tail}`;
}

function extractExistingScoreTiers(configText: string): ScoreTier[] {
  const blockMatch = configText.match(/PGF\.SCORE_COLORS = \{([\s\S]*?)^\}/m);
  if (!blockMatch) {
    throw new Error("Could not find PGF.SCORE_COLORS block in src/Config.lua.");
  }

  const rowPattern = /\{\s*(\d+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\}/g;
  const scoreTiers: ScoreTier[] = [];

  for (const match of blockMatch[1].matchAll(rowPattern)) {
    scoreTiers.push({
      score: Number(match[1]),
      rgbFloat: [Number(match[2]), Number(match[3]), Number(match[4])],
    });
  }

  return scoreTiers;
}

function summarizeDiff(existingScoreTiers: ScoreTier[], nextScoreTiers: ScoreTier[]): DiffSummary {
  const existingByScore = new Map(existingScoreTiers.map((tier) => [tier.score, tier]));
  const nextByScore = new Map(nextScoreTiers.map((tier) => [tier.score, tier]));
  let added = 0;
  let removed = 0;
  let changed = 0;
  let unchanged = 0;

  for (const [score, nextTier] of nextByScore) {
    const existingTier = existingByScore.get(score);
    if (!existingTier) {
      added += 1;
      continue;
    }

    const same = existingTier.rgbFloat.every((channel, index) => channel === nextTier.rgbFloat[index]);
    if (same) {
      unchanged += 1;
    } else {
      changed += 1;
    }
  }

  for (const score of existingByScore.keys()) {
    if (!nextByScore.has(score)) {
      removed += 1;
    }
  }

  return { added, removed, changed, unchanged };
}

function printDryRunSummary(existingScoreTiers: ScoreTier[], nextScoreTiers: ScoreTier[], changed: boolean): void {
  const diff = summarizeDiff(existingScoreTiers, nextScoreTiers);
  const existingTop = existingScoreTiers[0]?.score ?? 0;
  const existingBottom = existingScoreTiers.at(-1)?.score ?? 0;
  const nextTop = nextScoreTiers[0]?.score ?? 0;
  const nextBottom = nextScoreTiers.at(-1)?.score ?? 0;

  console.log("Dry run only. No files will be modified.");
  console.log(`Existing tiers: ${existingScoreTiers.length} (${existingTop} -> ${existingBottom})`);
  console.log(`Fetched tiers:  ${nextScoreTiers.length} (${nextTop} -> ${nextBottom})`);
  console.log(
    `Diff summary: added=${diff.added} removed=${diff.removed} changed=${diff.changed} unchanged=${diff.unchanged}`,
  );
  console.log(`Fetched preview: ${formatScoreTierPreview(nextScoreTiers)}`);
  console.log(changed ? `Would update ${CONFIG_PATH}.` : "PGF.SCORE_COLORS is already up to date.");
}

function buildLuaTable(scoreTiers: ScoreTier[]): string {
  const lines = scoreTiers.map(({ score, rgbFloat }) => {
    const [red, green, blue] = rgbFloat;
    return `    { ${score}, ${formatChannel(red)}, ${formatChannel(green)}, ${formatChannel(blue)} },`;
  });

  return [
    "PGF.SCORE_COLORS = {",
    ...lines,
    "}",
  ].join("\n");
}

function replaceScoreColorsBlock(configText: string, replacementBlock: string): string {
  const pattern = /PGF\.SCORE_COLORS = \{[\s\S]*?^\}/m;
  if (!pattern.test(configText)) {
    throw new Error("Could not find PGF.SCORE_COLORS block in src/Config.lua.");
  }

  return configText.replace(pattern, replacementBlock);
}

async function main() {
  const dryRun = Deno.args.includes("--dry-run");
  const response = await fetch(SCORE_TIER_URL);
  if (!response.ok) {
    throw new Error(`Failed to fetch Raider.IO score tiers: ${response.status} ${response.statusText}`);
  }

  const payload = await response.json();
  const scoreTiers = extractScoreTiers(payload);
  validateScoreTiers(scoreTiers);
  const replacementBlock = buildLuaTable(scoreTiers);

  const currentConfig = await Deno.readTextFile(CONFIG_PATH);
  const existingScoreTiers = extractExistingScoreTiers(currentConfig);
  const updatedConfig = replaceScoreColorsBlock(currentConfig, replacementBlock);
  const hasChanges = updatedConfig !== currentConfig;

  if (dryRun) {
    printDryRunSummary(existingScoreTiers, scoreTiers, hasChanges);
    return;
  }

  if (!hasChanges) {
    console.log("PGF.SCORE_COLORS is already up to date.");
    return;
  }

  await Deno.writeTextFile(CONFIG_PATH, updatedConfig);
  console.log(`Updated ${CONFIG_PATH} with ${scoreTiers.length} Raider.IO score tiers.`);
}

if (import.meta.main) {
  await main();
}