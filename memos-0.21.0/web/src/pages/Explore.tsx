import { Button } from "@mui/joy";
import classNames from "classnames";
import { useEffect, useRef, useState } from "react";
import Empty from "@/components/Empty";
import { ExploreSidebar, ExploreSidebarDrawer } from "@/components/ExploreSidebar";
import Icon from "@/components/Icon";
import MemoFilter from "@/components/MemoFilter";
import MemoView from "@/components/MemoView";
import MobileHeader from "@/components/MobileHeader";
import { DEFAULT_LIST_MEMOS_PAGE_SIZE } from "@/helpers/consts";
import { getTimeStampByDate } from "@/helpers/datetime";
import useCurrentUser from "@/hooks/useCurrentUser";
import useFilterWithUrlParams from "@/hooks/useFilterWithUrlParams";
import useResponsiveWidth from "@/hooks/useResponsiveWidth";
import { useMemoList, useMemoStore } from "@/store/v1";
import { useTranslate } from "@/utils/i18n";

const Explore = () => {
  const t = useTranslate();
  const { md } = useResponsiveWidth();
  const user = useCurrentUser();
  const memoStore = useMemoStore();
  const memoList = useMemoList();
  const [isRequesting, setIsRequesting] = useState(true);
  const nextPageTokenRef = useRef<string | undefined>(undefined);
  const { tag: tagQuery, text: textQuery } = useFilterWithUrlParams();
  const sortedMemos = memoList.value.sort((a, b) => getTimeStampByDate(b.displayTime) - getTimeStampByDate(a.displayTime));

  useEffect(() => {
    nextPageTokenRef.current = undefined;
    memoList.reset();
    fetchMemos();
  }, [tagQuery, textQuery]);

  const fetchMemos = async () => {
    const filters = [`row_status == "NORMAL"`, `visibilities == [${user ? "'PUBLIC', 'PROTECTED'" : "'PUBLIC'"}]`];
    const contentSearch: string[] = [];
    if (tagQuery) {
      contentSearch.push(JSON.stringify(`#${tagQuery}`));
    }
    if (textQuery) {
      contentSearch.push(JSON.stringify(textQuery));
    }
    if (contentSearch.length > 0) {
      filters.push(`content_search == [${contentSearch.join(", ")}]`);
    }
    setIsRequesting(true);
    const data = await memoStore.fetchMemos({
      pageSize: DEFAULT_LIST_MEMOS_PAGE_SIZE,
      filter: filters.join(" && "),
      pageToken: nextPageTokenRef.current,
    });
    setIsRequesting(false);
    nextPageTokenRef.current = data.nextPageToken;
  };

  return (
    <section className="@container w-full max-w-5xl min-h-full flex flex-col justify-start items-center sm:pt-3 md:pt-6 pb-8">
      {!md && (
        <MobileHeader>
          <ExploreSidebarDrawer />
        </MobileHeader>
      )}
      <div className={classNames("w-full flex flex-row justify-start items-start px-4 sm:px-6 gap-4")}>
        <div className={classNames(md ? "w-[calc(100%-15rem)]" : "w-full")}>
          <div className="flex flex-col justify-start items-start w-full max-w-full">
            <MemoFilter className="px-2 pb-2" />
            {sortedMemos.map((memo) => (
              <MemoView key={`${memo.name}-${memo.updateTime}`} memo={memo} showCreator showVisibility showPinned />
            ))}
            {isRequesting ? (
              <div className="flex flex-row justify-center items-center w-full my-4 text-gray-400">
                <Icon.Loader className="w-4 h-auto animate-spin mr-1" />
                <p className="text-sm italic">{t("memo.fetching-data")}</p>
              </div>
            ) : !nextPageTokenRef.current ? (
              sortedMemos.length === 0 && (
                <div className="w-full mt-12 mb-8 flex flex-col justify-center items-center italic">
                  <Empty />
                  <p className="mt-2 text-gray-600 dark:text-gray-400">{t("message.no-data")}</p>
                </div>
              )
            ) : (
              <div className="w-full flex flex-row justify-center items-center my-4">
                <Button variant="plain" endDecorator={<Icon.ArrowDown className="w-5 h-auto" />} onClick={fetchMemos}>
                  {t("memo.fetch-more")}
                </Button>
              </div>
            )}
          </div>
        </div>
        {md && (
          <div className="sticky top-0 left-0 shrink-0 -mt-6 w-56 h-full">
            <ExploreSidebar className="py-6" />
          </div>
        )}
      </div>
    </section>
  );
};

export default Explore;
