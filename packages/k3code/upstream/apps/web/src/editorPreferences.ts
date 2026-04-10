import { EDITORS, EditorId, type LocalApi } from "@t3tools/contracts";
import { useCallback, useMemo } from "react";
import { useSettings, useUpdateSettings } from "./hooks/useSettings";
import { getLocalStorageItem, removeLocalStorageItem } from "./hooks/useLocalStorage";

const LEGACY_LAST_EDITOR_KEY = "t3code:last-editor";

export function clearLegacyPreferredEditorPreference(): void {
  removeLocalStorageItem(LEGACY_LAST_EDITOR_KEY);
}

export function resolvePreferredEditor(
  availableEditors: ReadonlyArray<EditorId>,
  preferredEditor: EditorId | null | undefined,
): EditorId | null {
  const availableEditorIds = new Set(availableEditors);
  const firstAvailableEditor =
    EDITORS.find((editor) => availableEditorIds.has(editor.id))?.id ?? null;

  if (preferredEditor) {
    return availableEditorIds.has(preferredEditor) ? preferredEditor : firstAvailableEditor;
  }

  const legacyEditor = getLocalStorageItem(LEGACY_LAST_EDITOR_KEY, EditorId);
  if (legacyEditor && availableEditorIds.has(legacyEditor)) {
    return legacyEditor;
  }

  return firstAvailableEditor;
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
  const editor = resolvePreferredEditor(config.availableEditors, clientSettings?.preferredEditor);
  if (!editor) throw new Error("No available editors found.");
  await api.shell.openInEditor(targetPath, editor);
  return editor;
}
