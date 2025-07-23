import { Resource } from "@/types/proto/api/v2/resource_service";
import Icon from "../Icon";
import ResourceIcon from "../ResourceIcon";

interface Props {
  resourceList: Resource[];
  setResourceList: (resourceList: Resource[]) => void;
}

const ResourceListView = (props: Props) => {
  const { resourceList, setResourceList } = props;

  const handleDeleteResource = async (name: string) => {
    setResourceList(resourceList.filter((resource) => resource.name !== name));
  };

  return (
    <>
      {resourceList.length > 0 && (
        <div className="w-full flex flex-row justify-start flex-wrap gap-2 mt-2">
          {resourceList.map((resource) => {
            return (
              <div
                key={resource.name}
                className="max-w-full flex flex-row justify-start items-center flex-nowrap gap-x-1 bg-zinc-100 dark:bg-zinc-900 px-2 py-1 rounded text-gray-500 dark:text-gray-400"
              >
                <ResourceIcon resource={resource} className="!w-4 !h-4 !opacity-100" />
                <span className="text-sm max-w-[8rem] truncate">{resource.filename}</span>
                <Icon.X
                  className="w-4 h-auto cursor-pointer opacity-60 hover:opacity-100"
                  onClick={() => handleDeleteResource(resource.name)}
                />
              </div>
            );
          })}
        </div>
      )}
    </>
  );
};

export default ResourceListView;
