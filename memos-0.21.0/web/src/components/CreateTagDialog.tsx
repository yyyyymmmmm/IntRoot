import { Button, IconButton, Input } from "@mui/joy";
import React, { useEffect, useState } from "react";
import { toast } from "react-hot-toast";
import { tagServiceClient } from "@/grpcweb";
import useCurrentUser from "@/hooks/useCurrentUser";
import { useTagStore } from "@/store/module";
import { useTranslate } from "@/utils/i18n";
import { TAG_REG } from "@/utils/tag";
import { generateDialog } from "./Dialog";
import Icon from "./Icon";
import OverflowTip from "./kit/OverflowTip";

type Props = DialogProps;

const validateTagName = (tagName: string): boolean => {
  const matchResult = `#${tagName}`.match(TAG_REG);
  if (!matchResult || matchResult[1] !== tagName) {
    return false;
  }
  return true;
};

const CreateTagDialog: React.FC<Props> = (props: Props) => {
  const { destroy } = props;
  const t = useTranslate();
  const currentUser = useCurrentUser();
  const tagStore = useTagStore();
  const [tagName, setTagName] = useState<string>("");
  const [suggestTagNameList, setSuggestTagNameList] = useState<string[]>([]);
  const [showTagSuggestions, setShowTagSuggestions] = useState<boolean>(false);
  const tagNameList = tagStore.state.tags;
  const shownSuggestTagNameList = suggestTagNameList.filter((tag) => !tagNameList.includes(tag));

  useEffect(() => {
    tagServiceClient
      .getTagSuggestions({
        user: currentUser.name,
      })
      .then(({ tags }) => {
        setSuggestTagNameList(tags.filter((tag) => validateTagName(tag)));
      });
  }, [tagNameList]);

  const handleTagNameInputKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === "Enter") {
      handleSaveBtnClick();
    }
  };

  const handleTagNameChanged = (event: React.ChangeEvent<HTMLInputElement>) => {
    const tagName = event.target.value;
    setTagName(tagName.trim());
  };

  const handleUpsertTag = async (tagName: string) => {
    await tagStore.upsertTag(tagName);
  };

  const handleToggleShowSuggestionTags = () => {
    setShowTagSuggestions((state) => !state);
  };

  const handleSaveBtnClick = async () => {
    if (!validateTagName(tagName)) {
      toast.error(t("tag.invalid-tag-name"));
      return;
    }

    try {
      await tagStore.upsertTag(tagName);
      setTagName("");
    } catch (error: any) {
      console.error(error);
      toast.error(error.response.data.message);
    }
  };

  const handleDeleteTag = async (tag: string) => {
    await tagStore.deleteTag(tag);
  };

  const handleSaveSuggestTagList = async () => {
    for (const tagName of suggestTagNameList) {
      if (validateTagName(tagName)) {
        await tagStore.upsertTag(tagName);
      }
    }
  };

  return (
    <>
      <div className="dialog-header-container">
        <p className="title-text">{t("tag.create-tag")}</p>
        <IconButton size="sm" onClick={() => destroy()}>
          <Icon.X className="w-5 h-auto" />
        </IconButton>
      </div>
      <div className="dialog-content-container !w-80">
        <Input
          className="mb-2"
          size="md"
          placeholder={t("tag.tag-name")}
          value={tagName}
          onChange={handleTagNameChanged}
          onKeyDown={handleTagNameInputKeyDown}
          fullWidth
          startDecorator={<Icon.Hash className="w-4 h-auto" />}
          endDecorator={<Icon.Check onClick={handleSaveBtnClick} className="w-4 h-auto cursor-pointer hover:opacity-80" />}
        />
        {tagNameList.length > 0 && (
          <>
            <p className="w-full mt-2 mb-1 text-sm text-gray-400">{t("tag.all-tags")}</p>
            <div className="w-full flex flex-row justify-start items-start flex-wrap">
              {Array.from(tagNameList)
                .sort()
                .map((tag) => (
                  <OverflowTip
                    key={tag}
                    className="max-w-[120px] text-sm mr-2 mt-1 font-mono cursor-pointer dark:text-gray-300 hover:opacity-60 hover:line-through"
                  >
                    <span className="w-full" onClick={() => handleDeleteTag(tag)}>
                      #{tag}
                    </span>
                  </OverflowTip>
                ))}
            </div>
          </>
        )}

        {shownSuggestTagNameList.length > 0 && (
          <>
            <div className="mt-4 mb-1 text-sm w-full flex flex-row justify-start items-center">
              <span className="text-gray-400 mr-2">{t("tag.tag-suggestions")}</span>
              <span
                className="text-xs border border-gray-200 rounded-md px-1 leading-5 cursor-pointer text-gray-600 hover:shadow dark:border-zinc-700 dark:text-gray-400"
                onClick={handleToggleShowSuggestionTags}
              >
                {showTagSuggestions ? t("tag.hide") : t("tag.show")}
              </span>
            </div>
            {showTagSuggestions && (
              <>
                <div className="w-full flex flex-row justify-start items-start flex-wrap mb-2">
                  {shownSuggestTagNameList.map((tag) => (
                    <OverflowTip
                      key={tag}
                      className="max-w-[120px] text-sm mr-2 mt-1 font-mono cursor-pointer dark:text-gray-300 hover:opacity-60"
                    >
                      <span className="w-full" onClick={() => handleUpsertTag(tag)}>
                        #{tag}
                      </span>
                    </OverflowTip>
                  ))}
                </div>
                <Button size="sm" variant="outlined" onClick={handleSaveSuggestTagList}>
                  {t("tag.save-all")}
                </Button>
              </>
            )}
          </>
        )}
      </div>
    </>
  );
};

function showCreateTagDialog() {
  generateDialog(
    {
      className: "create-tag-dialog",
      dialogName: "create-tag-dialog",
    },
    CreateTagDialog,
  );
}

export default showCreateTagDialog;
