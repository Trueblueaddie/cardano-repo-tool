module RepoTool.Git.PullRebase
  ( gitPullRebase
  ) where

import           Data.List (isPrefixOf)

import           RepoTool.Git.Internal
import           RepoTool.Types


gitPullRebase :: RepoDirectory -> IO ()
gitPullRebase (RepoDirectory fpath) = do
  xs <- filter lineFilter . lines <$> readProcess gitBinary [ "-C", fpath, "pull", "--rebase" ]
  if null xs
    then printRepoNameOk fpath
    else do
      printRepoName fpath
      putStrLn ":"
      mapM_ (\ s -> putStrLn ("  " ++ s)) xs

lineFilter :: String -> Bool
lineFilter l
  | null l = False
  | "Your branch is up to date" `isPrefixOf` l = False
  | "Unpacking objects" `isPrefixOf` l = False
  | "Already up to date" `isPrefixOf` l = False
  | "Current branch " `isPrefixOf` l = False
  | "remote:" `isPrefixOf` l = False
  | "Unpacking objects:" `isPrefixOf` l = False
  | otherwise = True
