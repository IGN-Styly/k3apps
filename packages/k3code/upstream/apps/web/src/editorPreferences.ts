import { type EditorId, type LocalApi } from "@t3tools/contracts";
import { useCallback, useMemo } from "react";
import { useSettings, useUpdateSettings } from "./hooks/useSettings";
import { removeLocalStorageItem } from "./hooks/useLocalStorage";

const LEGACY_LAST_EDITOR_KEY = "t3code:last-editor";

export function clearLegacyPreferredEditorPreference(): void {
  removeLocalStorageItem(LEGACY_LAST_EDITOR_KEY);
}

export function resolvePreferredEditor(
  availableEditors: ReadonlyArray<EditorId>,
  preferredEditor: EditorId | null | undefined,
): EditorId | null {
  if (!preferredEditor) {
    return null;
  }
  return availableEditors.includes(preferredEditor) ? preferredEditor : null;
}

export function usePreferredEditor(availableEditors: ReadonlyArray<EditorId>) {
  const preferredEditor = useSettings((settings) => settings.preferredEditor);
  const { updateSettings } = useUpdateSettings();

  const effectiveEditor = useMemo(() => {
    return resolvePreferredEditor(availableEditors, preferredEditor);
  }, [availableEditors, preferredEditor]);

  const setPreferredEditor = useCallback(
    (editor: EditorId | null) => {
      clearLegacyPreferredEditorPreference();
      updateSettings({ preferredEditor: editor });
    },
    [updateSettings],
  );

  return [effectiveEditor, setPreferredEditor] as const;
}

export async function openInPreferredEditor(api: LocalApi, targetPath: string): Promise<EditorId> {
  const [config, clientSettings] = await Promise.all([
    api.server.getConfig(),
    api.persistence.getClientSettings(),
  ]);
  const preferredEditor = clientSettings?.preferredEditor;
  const editor = resolvePreferredEditor(config.availableEditors, clientSettings?.preferredEditor);
  if (!editor) {
    if (config.availableEditors.length === 0) {
      throw new Error("No available editors found.");
    }
    if (!preferredEditor) {
      throw new Error("No preferred editor selected.");
    }
    throw new Error("Preferred editor is unavailable.");
  }
  await api.shell.openInEditor(targetPath, editor);
  return editor;
}
