require 'r10k/git'
require 'r10k/git/base_repository'
require 'r10k/logging'

# Create and manage Git bare repositories.
class R10K::Git::BareRepository < R10K::Git::BaseRepository

  # @return [Pathname] The path to this Git repository
  def git_dir
    @path
  end

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote)
    git ['clone', '--mirror', remote, git_dir.to_s]
  end

  def fetch
    git ['fetch', '--prune'], :git_dir => git_dir.to_s
  end

  def exist?
    @path.exist?
  end

  # @return [Array<String>] All local branches in this repository
  def branches
    output = git %w[for-each-ref refs/heads --format %(refname)], :git_dir => git_dir.to_s
    output.stdout.scan(%r[refs/heads/(.*)$]).flatten
  end

  # @return [Array<String>] All tags in this repository
  def tags
    output = git %w[for-each-ref refs/tags --format %(refname)], :git_dir => git_dir.to_s
    output.stdout.scan(%r[refs/tags/(.*)$]).flatten
  end

  # Resolve the given Git ref to a commit
  #
  # @param pattern [String] The git ref to resolve
  # @return [String, nil] The commit SHA if the ref could be resolved, nil otherwise.
  def resolve(pattern)
    result = git ['rev-parse', "#{pattern}^{commit}"], :git_dir => git_dir.to_s, :raise_on_fail => false
    if result.success?
      result.stdout
    end
  end

  # @return [Symbol] The type of the given ref, one of :branch, :tag, :commit, or :unknown
  def ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif tags.include? pattern
      :tag
    elsif resolve(pattern)
      :commit
    else
      :unknown
    end
  end
end
