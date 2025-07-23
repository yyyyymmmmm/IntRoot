import { Button, IconButton, Input } from "@mui/joy";
import { useState } from "react";
import { toast } from "react-hot-toast";
import * as api from "@/helpers/api";
import { useGlobalStore } from "@/store/module";
import { useTranslate } from "@/utils/i18n";
import { generateDialog } from "./Dialog";
import Icon from "./Icon";

type Props = DialogProps;

interface State {
  disablePasswordLogin: boolean;
}

const DisablePasswordLoginDialog: React.FC<Props> = ({ destroy }: Props) => {
  const t = useTranslate();
  const globalStore = useGlobalStore();
  const systemStatus = globalStore.state.systemStatus;
  const [state, setState] = useState<State>({
    disablePasswordLogin: systemStatus.disablePasswordLogin,
  });
  const [confirmedOnce, setConfirmedOnce] = useState(false);
  const [typingConfirmation, setTypingConfirmation] = useState("");

  const handleCloseBtnClick = () => {
    destroy();
  };

  const allowConfirmAction = () => {
    return !confirmedOnce || typingConfirmation === "CONFIRM";
  };

  const handleConfirmBtnClick = async () => {
    if (!confirmedOnce) {
      setConfirmedOnce(true);
    } else {
      setState({ ...state, disablePasswordLogin: true });
      globalStore.setSystemStatus({ disablePasswordLogin: true });
      try {
        await api.upsertSystemSetting({
          name: "disable-password-login",
          value: JSON.stringify(true),
        });
        handleCloseBtnClick();
      } catch (error: any) {
        console.error(error);
        toast.error(error.response.data.message);
      }
    }
  };

  const handleTypingConfirmationChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    const text = e.target.value as string;
    setTypingConfirmation(text);
  };

  return (
    <>
      <div className="dialog-header-container">
        <p className="title-text">{t("setting.system-section.disable-password-login")}</p>
        <IconButton size="sm" onClick={handleCloseBtnClick}>
          <Icon.X className="w-5 h-auto" />
        </IconButton>
      </div>
      <div className="dialog-content-container !w-72">
        {confirmedOnce ? (
          <>
            <p className="">{t("setting.system-section.disable-password-login-final-warning")}</p>
            <Input className="w-full mt-2" value={typingConfirmation} onChange={handleTypingConfirmationChanged} />
          </>
        ) : (
          <p className="">{t("setting.system-section.disable-password-login-warning")}</p>
        )}
        <div className="mt-4 w-full flex flex-row justify-end items-center space-x-2">
          <Button variant="plain" color="neutral" onClick={handleCloseBtnClick}>
            {t("common.close")}
          </Button>
          <Button onClick={handleConfirmBtnClick} color="danger" disabled={!allowConfirmAction()}>
            {t("common.confirm")}
          </Button>
        </div>
      </div>
    </>
  );
};

function showDisablePasswordLoginDialog() {
  generateDialog(
    {
      className: "disable-password-login-dialog",
      dialogName: "disable-password-login-dialog",
    },
    DisablePasswordLoginDialog,
  );
}

export default showDisablePasswordLoginDialog;
