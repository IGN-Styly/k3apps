import { type EditorId } from "@t3tools/contracts";
import { FolderClosedIcon } from "lucide-react";
import {
  AntigravityIcon,
  CursorIcon,
  type Icon,
  IntelliJIdeaIcon,
  TraeIcon,
  VisualStudioCode,
  VisualStudioCodeInsiders,
  VSCodium,
  Zed,
} from "./components/Icons";
import { isMacPlatform, isWindowsPlatform } from "./lib/utils";

export interface EditorOption {
  readonly value: EditorId;
  readonly label: string;
  readonly Icon: Icon;
}

const STATIC_EDITOR_OPTIONS = {
  antigravity: {
    label: "Antigravity",
    Icon: AntigravityIcon,
  },
  cursor: {
    label: "Cursor",
    Icon: CursorIcon,
  },
  idea: {
    label: "IntelliJ IDEA",
    Icon: IntelliJIdeaIcon,
  },
  trae: {
    label: "Trae",
    Icon: TraeIcon,
  },
  vscode: {
    label: "VS Code",
    Icon: VisualStudioCode,
  },
  "vscode-insiders": {
    label: "VS Code Insiders",
    Icon: VisualStudioCodeInsiders,
  },
  vscodium: {
    label: "VSCodium",
    Icon: VSCodium,
  },
  zed: {
    label: "Zed",
    Icon: Zed,
  },
} as const satisfies Record<Exclude<EditorId, "file-manager">, { label: string; Icon: Icon }>;

export function getEditorOption(platform: string, editorId: EditorId): EditorOption {
  if (editorId === "file-manager") {
    return {
      value: editorId,
      label: isMacPlatform(platform)
        ? "Finder"
        : isWindowsPlatform(platform)
          ? "Explorer"
          : "Files",
      Icon: FolderClosedIcon,
    };
  }

  const option = STATIC_EDITOR_OPTIONS[editorId];
  return {
    value: editorId,
    label: option.label,
    Icon: option.Icon,
  };
}

export function resolveEditorOptions(
  platform: string,
  availableEditors: ReadonlyArray<EditorId>,
): ReadonlyArray<EditorOption> {
  return availableEditors.map((editorId) => getEditorOption(platform, editorId));
}
