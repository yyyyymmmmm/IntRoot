import { workspaceServiceClient } from "@/grpcweb";
import * as api from "@/helpers/api";
import storage from "@/helpers/storage";
import i18n from "@/i18n";
import { WorkspaceProfile } from "@/types/proto/api/v2/workspace_service";
import { findNearestMatchedLanguage } from "@/utils/i18n";
import store, { useAppSelector } from "../";
import { setAppearance, setGlobalState, setLocale } from "../reducer/global";

export const initialGlobalState = async () => {
  const defaultGlobalState = {
    locale: "en" as Locale,
    appearance: "system" as Appearance,
    systemStatus: {
      disablePasswordLogin: false,
      disablePublicMemos: false,
      maxUploadSizeMiB: 0,
      memoDisplayWithUpdatedTs: false,
      customizedProfile: {
        name: "Memos",
        logoUrl: "/logo.webp",
        description: "",
        locale: "en",
        appearance: "system",
      },
    } as SystemStatus,
    workspaceProfile: WorkspaceProfile.fromPartial({}),
  };

  const { workspaceProfile } = await workspaceServiceClient.getWorkspaceProfile({});
  if (workspaceProfile) {
    defaultGlobalState.workspaceProfile = workspaceProfile;
  }

  const { data } = await api.getSystemStatus();
  if (data) {
    const customizedProfile = data.customizedProfile;
    defaultGlobalState.systemStatus = {
      ...data,
      customizedProfile: {
        name: customizedProfile.name || "Memos",
        logoUrl: customizedProfile.logoUrl || "/logo.webp",
        description: customizedProfile.description,
        locale: customizedProfile.locale || "en",
        appearance: customizedProfile.appearance || "system",
      },
    };
    // Use storageLocale > userLocale > customizedProfile.locale (server's default locale)
    // Initially, storageLocale is undefined and user is not logged in, so use server's default locale.
    // User can change locale in login/sign up page, set storageLocale and override userLocale after logged in.
    // Otherwise, storageLocale remains undefined and if userLocale has value after user logged in, set to storageLocale and re-render.
    // Otherwise, use server's default locale, set to storageLocale.
    const { locale: storageLocale, appearance: storageAppearance } = storage.get(["locale", "appearance"]);
    defaultGlobalState.locale =
      storageLocale || defaultGlobalState.systemStatus.customizedProfile.locale || findNearestMatchedLanguage(i18n.language);
    defaultGlobalState.appearance = storageAppearance || defaultGlobalState.systemStatus.customizedProfile.appearance;
  }
  store.dispatch(setGlobalState(defaultGlobalState));
};

export const useGlobalStore = () => {
  const state = useAppSelector((state) => state.global);

  return {
    state,
    getState: () => {
      return store.getState().global;
    },
    getDisablePublicMemos: () => {
      return store.getState().global.systemStatus.disablePublicMemos;
    },
    isDev: () => {
      return state.workspaceProfile.mode !== "prod";
    },
    fetchSystemStatus: async () => {
      const { data: systemStatus } = await api.getSystemStatus();
      store.dispatch(setGlobalState({ systemStatus: systemStatus }));
      return systemStatus;
    },
    setSystemStatus: (systemStatus: Partial<SystemStatus>) => {
      store.dispatch(
        setGlobalState({
          systemStatus: {
            ...state.systemStatus,
            ...systemStatus,
          },
        }),
      );
    },
    setLocale: (locale: Locale) => {
      // Set storageLocale to user selected locale.
      storage.set({
        locale: locale,
      });
      store.dispatch(setLocale(locale));
    },
    setAppearance: (appearance: Appearance) => {
      // Set storageAppearance to user selected appearance.
      storage.set({
        appearance: appearance,
      });
      store.dispatch(setAppearance(appearance));
    },
  };
};
