import React from 'react';
import { WebFRouter } from '../router';
import { WebFListView } from '@openwebf/react-core-ui';

interface CupertinoShowcaseItemProps {
  label: string;
  desc: string;
  to?: string;
  navigateTo: (path: string) => void;
}

const CupertinoShowcaseItem = (props: CupertinoShowcaseItemProps) => {
  return (
    <div
      className={`flex items-center p-4 border-b border-[#f0f0f0] cursor-pointer transition-colors hover:bg-surface-hover ${props.to ? '' : 'pointer-events-none opacity-60'}`}
      onClick={props.to ? () => props.navigateTo(props.to!) : undefined}
    >
      <div className="flex-1">
        <div className="text-[16px] font-semibold text-[#2c3e50] mb-1">{props.label}</div>
        <div className="text-[14px] text-[#7f8c8d] leading-snug">{props.desc}</div>
      </div>
      <div className="text-[16px] text-[#bdc3c7] font-bold">&gt;</div>
    </div>
  );
};

export const CupertinoShowcasePage: React.FC = () => {
  const navigateTo = (path: string) => WebFRouter.pushState({}, path);

  return (
    <div id="main" className="min-h-screen w-full bg-surface">
      <WebFListView className="w-full px-3 md:px-6 max-w-4xl mx-auto py-6">
          <div className="w-full flex justify-center items-center">
            <div className="bg-gradient-to-tr from-blue-500 to-cyan-400 p-6 rounded-2xl text-white shadow">
              <h1 className="text-[28px] font-bold mb-2 drop-shadow">Cupertino UI</h1>
              <p className="text-[16px]/[1.5] opacity-90">iOS-style components and interactions built with WebF</p>
            </div>
          </div>

          <div className="mt-6">
            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Theme & Colors</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="Cupertino Colors" desc="Static and dynamic Cupertino colors" to="/cupertino/colors" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="Cupertino Icons" desc="iOS SF Symbols icon set" to="/cupertino/icons" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Navigation, Tabs & Pages</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="Tabs" desc="TabScaffold · TabBar · TabView · Controller" to="/cupertino/tabs" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Dialogs, Sheets & Menus</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="Cupertino Alert Dialog" desc="Alerts & dialog actions" to="/cupertino/alert" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="Cupertino Action Sheet" desc="Action sheet and sheet actions" to="/cupertino/actionsheet" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="Cupertino Modal Popup" desc="Bottom sheet style modal popup" to="/cupertino/modal-popup" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="Cupertino Context Menu" desc="Peek and pop context actions" to="/cupertino/context-menu" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Lists & Forms</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="CupertinoListSection" desc="Grouped list sections" to="/cupertino/list-section" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoListTile" desc="iOS-style list tiles" to="/cupertino/list-tile" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoFormSection" desc="Form rows and grouped settings" to="/cupertino/form-section" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Text Input & Search</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="CupertinoTextField" desc="Single-line iOS-style text input" to="/cupertino/text-field" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoTextFormFieldRow" desc="Inline text field row for forms" to="/cupertino/text-form-field-row" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoSearchTextField" desc="iOS-style search bar" to="/cupertino/search-text-field" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Pickers</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="CupertinoDatePicker" desc="iOS date & time picker" to="/cupertino/date-picker" navigateTo={navigateTo} />
            </div>

            <h2 className="text-lg font-semibold text-fg-primary mb-3 pl-3 border-l-4 border-blue-500">Controls</h2>
            <div className="mb-5 bg-surface-secondary rounded-xl shadow overflow-hidden border border-line">
              <CupertinoShowcaseItem label="Cupertino Buttons" desc="Buttons with iOS styling" to="/cupertino/buttons" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoSwitch" desc="iOS-style toggle" to="/cupertino/switch" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoSlider" desc="Value selection slider" to="/cupertino/slider" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="Sliding Segmented Control" desc="Segmented control with sliding thumb" to="/cupertino/sliding-segmented-control" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoCheckBox" desc="iOS checkbox" to="/cupertino/checkbox" navigateTo={navigateTo} />
              <CupertinoShowcaseItem label="CupertinoRadio" desc="iOS radio button" to="/cupertino/radio" navigateTo={navigateTo} />
            </div>

          </div>
      </WebFListView>
    </div>
  );
};
