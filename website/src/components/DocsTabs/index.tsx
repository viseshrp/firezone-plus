"use client";
import { Tabs as FlowbiteTabs, TabItem } from "flowbite-react";

function TabsGroup({ children }: { children: React.ReactNode }) {
  return (
    <div className="mb-4">
      <FlowbiteTabs className="shadow">{children}</FlowbiteTabs>
    </div>
  );
}

function TabsItem({
  children,
  title,
  ...props
}: {
  children: React.ReactNode;
  title: string;
}) {
  return (
    <TabItem title={title} {...props}>
      {children}
    </TabItem>
  );
}

export { TabsGroup, TabsItem };
