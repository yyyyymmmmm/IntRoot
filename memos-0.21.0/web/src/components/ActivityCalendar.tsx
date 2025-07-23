import { Tooltip } from "@mui/joy";
import classNames from "classnames";
import { getNormalizedDateString, getDateWithOffset } from "@/helpers/datetime";

interface Props {
  // Format: 2021-1
  month: string;
  data: Record<string, number>;
  onClick?: (date: string) => void;
}

const getCellAdditionalStyles = (count: number, maxCount: number) => {
  if (count === 0) {
    return "bg-gray-100 text-gray-400 dark:bg-gray-700 dark:text-gray-500";
  }

  const ratio = count / maxCount;
  if (ratio > 0.7) {
    return "bg-blue-600 text-gray-100 dark:opacity-80";
  } else if (ratio > 0.4) {
    return "bg-blue-400 text-gray-200 dark:opacity-80";
  } else {
    return "bg-blue-300 text-gray-600 dark:opacity-80";
  }
};

const ActivityCalendar = (props: Props) => {
  const { month: monthStr, data, onClick } = props;
  const year = new Date(monthStr).getUTCFullYear();
  const month = new Date(monthStr).getUTCMonth() + 1;
  const dayInMonth = new Date(year, month, 0).getDate();
  const firstDay = new Date(year, month - 1, 1).getDay();
  const lastDay = new Date(year, month - 1, dayInMonth).getDay();
  const maxCount = Math.max(...Object.values(data));
  const days = [];

  for (let i = 0; i < firstDay; i++) {
    days.push(0);
  }
  for (let i = 1; i <= dayInMonth; i++) {
    days.push(i);
  }
  for (let i = 0; i < 6 - lastDay; i++) {
    days.push(0);
  }

  return (
    <div className={classNames("w-36 h-auto p-0.5 shrink-0 grid grid-cols-7 grid-flow-row gap-1")}>
      {days.map((day, index) => {
        const date = getNormalizedDateString(
          getDateWithOffset(`${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`),
        );
        const count = data[date] || 0;
        const isToday = new Date().toDateString() === new Date(date).toDateString();
        const tooltipText = count ? `${count} memos in ${date}` : date;
        return day ? (
          <Tooltip className="shrink-0" key={`${date}-${index}`} title={tooltipText} placement="top" arrow>
            <div
              className={classNames(
                "w-4 h-4 text-[9px] rounded-md flex justify-center items-center border border-transparent",
                getCellAdditionalStyles(count, maxCount),
                isToday && "border-gray-600 dark:!border-gray-500",
              )}
              onClick={() => count && onClick && onClick(date)}
            >
              {day}
            </div>
          </Tooltip>
        ) : (
          <div
            key={`${date}-${index}`}
            className={classNames(
              "shrink-0 opacity-30 w-4 h-4 rounded-md flex justify-center items-center border border-transparent",
              getCellAdditionalStyles(count, maxCount),
            )}
          ></div>
        );
      })}
    </div>
  );
};

export default ActivityCalendar;
