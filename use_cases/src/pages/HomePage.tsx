import React from 'react';
import {WebFRouter} from '../router';
import {WebFListView} from '@openwebf/react-core-ui';

interface HomeRowProps {
  title: string;
  desc: string;
  to: string;
  go: (path: string) => void;
}

const HomeRow = (props: HomeRowProps) => (
  <div
    className="flex items-center justify-between cursor-pointer transition-colors duration-200 rounded-lg -mx-3 sm:-mx-4 md:-mx-5 px-3 sm:px-4 md:px-5 py-3.5 md:py-4 hover:bg-surface-hover active:scale-[.98] min-h-11"
    onClick={() => props.go(props.to)}
  >
    <div className="flex-1 mr-2 md:mr-3">
      <div className="text-base sm:text-lg font-medium text-fg-primary mb-1">{props.title}</div>
      <div className="text-sm sm:text-base text-fg-secondary leading-snug">{props.desc}</div>
    </div>
    <div className="text-fg-secondary text-base select-none">&gt;</div>
  </div>
);

// Lean, curated homepage with catalog + quick demos
export const HomePage: React.FC = () => {
  const go = (path: string) => WebFRouter.pushState({}, path);

  return (
    <div id="main">
      <WebFListView className="min-h-screen w-full bg-surface pl-2 pr-2">
        {/* Start Here */}
        <div className="text-lg sm:text-xl md:text-2xl font-semibold text-fg-primary mb-2 mt-4">Start Here</div>
        <div className="bg-surface-secondary rounded-xl px-3 sm:px-4 md:px-5 mb-5 divide-y divide-line">
          <HomeRow
            title="Browse Feature Catalog"
            desc="Clean, organized groups of WebF showcases."
            to="/features"
            go={go}
          />
        </div>

        {/* Quick Demos */}
        <div className="text-lg sm:text-xl md:text-2xl font-semibold text-fg-primary mb-2">Quick Demos</div>
        <div className="bg-surface-secondary rounded-xl px-3 sm:px-4 md:px-5 mb-8 divide-y divide-line">
          <HomeRow title="Cupertino UI" desc="iOS-style components and interactions." to="/cupertino-showcase" go={go}/>
        </div>
      </WebFListView>
    </div>
  );
};
