import { Button, IconButton, Input } from "@mui/joy";
import { useState } from "react";
import { toast } from "react-hot-toast";
import * as api from "@/helpers/api";
import { useGlobalStore } from "@/store/module";
import { useTranslate } from "@/utils/i18n";
import { generateDialog } from "./Dialog";
import Icon from "./Icon";
import LearnMore from "./LearnMore";

interface Props extends DialogProps {
  localStoragePath?: string;
  confirmCallback?: () => void;
}

const UpdateLocalStorageDialog: React.FC<Props> = (props: Props) => {
  const t = useTranslate();
  const { destroy, localStoragePath, confirmCallback } = props;
  const globalStore = useGlobalStore();
  const [path, setPath] = useState(localStoragePath || "");

  const handleCloseBtnClick = () => {
    destroy();
  };

  const handleConfirmBtnClick = async () => {
    try {
      await api.upsertSystemSetting({
        name: "local-storage-path",
        value: JSON.stringify(path.trim()),
      });
      await globalStore.fetchSystemStatus();
    } catch (error: any) {
      console.error(error);
      if (error.response.data.error) {
        const errorText = error.response.data.error as string;
        const internalIndex = errorText.indexOf("internal=");
        if (internalIndex !== -1) {
          const internalError = errorText.substring(internalIndex + 9);
          toast.error(internalError);
        }
      } else {
        toast.error(error.response.data.message);
      }
    }
    if (confirmCallback) {
      confirmCallback();
    }
    destroy();
  };

  return (
    <>
      <div className="dialog-header-container">
        <p className="title-text">{t("setting.storage-section.update-local-path")}</p>
        <IconButton size="sm" onClick={handleCloseBtnClick}>
          <Icon.X className="w-5 h-auto" />
        </IconButton>
      </div>
      <div className="dialog-content-container max-w-xs">
        <p className="text-sm break-words mb-1">{t("setting.storage-section.update-local-path-description")}</p>
        <div className="flex flex-row items-center mb-2 gap-x-2">
          <span className="text-sm text-gray-400 break-all">e.g. {"assets/{timestamp}_{filename}"}</span>
          <LearnMore url="https://usememos.com/docs/advanced-settings/local-storage" />
        </div>
        <Input
          className="mb-2"
          placeholder={t("setting.storage-section.local-storage-path")}
          fullWidth
          value={path}
          onChange={(e) => setPath(e.target.value)}
        />
        <div className="mt-2 w-full flex flex-row justify-end items-center space-x-1">
          <Button variant="plain" color="neutral" onClick={handleCloseBtnClick}>
            {t("common.cancel")}
          </Button>
          <Button onClick={handleConfirmBtnClick}>{t("common.update")}</Button>
        </div>
      </div>
    </>
  );
};

function showUpdateLocalStorageDialog(localStoragePath?: string, confirmCallback?: () => void) {
  generateDialog(
    {
      className: "update-local-storage-dialog",
      dialogName: "update-local-storage-dialog",
    },
    UpdateLocalStorageDialog,
    { localStoragePath, confirmCallback },
  );
}

export default showUpdateLocalStorageDialog;
