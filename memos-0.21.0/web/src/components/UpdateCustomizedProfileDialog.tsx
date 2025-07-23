import { Button, IconButton, Input } from "@mui/joy";
import Textarea from "@mui/joy/Textarea/Textarea";
import { useState } from "react";
import { toast } from "react-hot-toast";
import * as api from "@/helpers/api";
import { useGlobalStore } from "@/store/module";
import { useTranslate } from "@/utils/i18n";
import AppearanceSelect from "./AppearanceSelect";
import { generateDialog } from "./Dialog";
import Icon from "./Icon";
import LocaleSelect from "./LocaleSelect";

type Props = DialogProps;

const UpdateCustomizedProfileDialog: React.FC<Props> = ({ destroy }: Props) => {
  const t = useTranslate();
  const globalStore = useGlobalStore();
  const [state, setState] = useState<CustomizedProfile>(globalStore.state.systemStatus.customizedProfile);

  const handleCloseButtonClick = () => {
    destroy();
  };

  const setPartialState = (partialState: Partial<CustomizedProfile>) => {
    setState((state) => {
      return {
        ...state,
        ...partialState,
      };
    });
  };

  const handleNameChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPartialState({
      name: e.target.value as string,
    });
  };

  const handleLogoUrlChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPartialState({
      logoUrl: e.target.value as string,
    });
  };

  const handleDescriptionChanged = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setPartialState({
      description: e.target.value as string,
    });
  };

  const handleLocaleSelectChange = (locale: Locale) => {
    setPartialState({
      locale: locale,
    });
  };

  const handleAppearanceSelectChange = (appearance: Appearance) => {
    setPartialState({
      appearance: appearance,
    });
  };

  const handleRestoreButtonClick = () => {
    setPartialState({
      name: "Memos",
      logoUrl: "/logo.webp",
      description: "",
      locale: "en",
      appearance: "system",
    });
  };

  const handleSaveButtonClick = async () => {
    if (state.name === "") {
      toast.error(t("message.fill-server-name"));
      return;
    }

    try {
      await api.upsertSystemSetting({
        name: "customized-profile",
        value: JSON.stringify(state),
      });
      await globalStore.fetchSystemStatus();
    } catch (error) {
      console.error(error);
      return;
    }
    toast.success(t("message.succeed-update-customized-profile"));
    destroy();
  };

  return (
    <>
      <div className="dialog-header-container">
        <p className="title-text">{t("setting.system-section.customize-server.title")}</p>
        <IconButton size="sm" onClick={handleCloseButtonClick}>
          <Icon.X className="w-5 h-auto" />
        </IconButton>
      </div>
      <div className="dialog-content-container min-w-[16rem]">
        <p className="text-sm mb-1">{t("setting.system-section.server-name")}</p>
        <Input className="w-full" type="text" value={state.name} onChange={handleNameChanged} />
        <p className="text-sm mb-1 mt-2">{t("setting.system-section.customize-server.icon-url")}</p>
        <Input className="w-full" type="text" value={state.logoUrl} onChange={handleLogoUrlChanged} />
        <p className="text-sm mb-1 mt-2">{t("setting.system-section.customize-server.description")}</p>
        <Textarea className="w-full" minRows="2" maxRows="4" value={state.description} onChange={handleDescriptionChanged} />
        <p className="text-sm mb-1 mt-2">{t("setting.system-section.customize-server.locale")}</p>
        <LocaleSelect className="!w-full" value={state.locale} onChange={handleLocaleSelectChange} />
        <p className="text-sm mb-1 mt-2">{t("setting.system-section.customize-server.appearance")}</p>
        <AppearanceSelect className="!w-full" value={state.appearance} onChange={handleAppearanceSelectChange} />
        <div className="mt-4 w-full flex flex-row justify-between items-center space-x-2">
          <div className="flex flex-row justify-start items-center">
            <Button variant="outlined" onClick={handleRestoreButtonClick}>
              {t("common.restore")}
            </Button>
          </div>
          <div className="flex flex-row justify-end items-center">
            <Button variant="plain" onClick={handleCloseButtonClick}>
              {t("common.cancel")}
            </Button>
            <Button onClick={handleSaveButtonClick}>{t("common.save")}</Button>
          </div>
        </div>
      </div>
    </>
  );
};

function showUpdateCustomizedProfileDialog() {
  generateDialog(
    {
      className: "update-customized-profile-dialog",
      dialogName: "update-customized-profile-dialog",
    },
    UpdateCustomizedProfileDialog,
  );
}

export default showUpdateCustomizedProfileDialog;
