## 寻址过程总结

1. 管理节点在收到元数据节点的的心跳信息时，如果没有元数据 Root 节点，则选择 ID 较小的作为元数据 Root 节点；
2. 客户端在 Mount 时，会初始化超级块，同时向管理节点询问元数据 Root 节点的 ID，然后向元数据 Root 节点获取 DirEntry 元数据；
3. 元数据节点初始化时，会先依次寻找 buddymir/inodes/38/51/root，inodes/38/51/root 来确定根目录的元数据；
4. 根据 Root 节点中 Root 的目录的元数据信息中包含的 OwnerID（确定目录所在节点）和 EntryID（根据 Hash 确定目录路径），就可以找到该目录的元数据位置；
5. 该目录所有文件的 DirEntry 文件中包含有文件的条带信息，以及数据分布的存储节点；
6. 该目录所有子目录的 DirEntry 文件的元数据中包含子目录的 OwnerID（即所在节点的 NodeID）和 EntryID，据此找到子目录的元数据目录，不断迭代，即可找到最终的文件。

## 元数据根节点的确定和获取

管理节点处理元数据节点的心跳信息时，如果发现目前没有 Root 节点，则会在已经注册的节点中选择 ID 最小的那个注册为元数据 Root 节点（这些信息最后都会保存在磁盘上）：

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/mgmtd/source/components/HeartbeatManager.cpp#L122-153>

```cpp
/**
 * @param rootIDHint empty string to auto-define root or a nodeID that is assumed to be the root
 * @return true if a new root node has been defined
 */
bool HeartbeatManager::initRootNode(NumNodeID rootIDHint, bool rootIsBuddyMirrored)
{
   // be careful: this method is also called from other threads
   // note: after this method, the root node might still be undefined (this is normal)

   bool setRootRes = false;

   if (rootIDHint || metaNodes->getSize())
   { // check whether root has already been set

      if (!rootIDHint)
         rootIDHint = metaNodes->getLowestNodeID();

      // set root to lowest ID (if no other root was set yet)
      setRootRes = Program::getApp()->getMetaRoot().setIfDefault(rootIDHint, rootIsBuddyMirrored);

      if(setRootRes)
      { // new root set
         log.log(Log_CRITICAL, "New root directory metadata node: " +
            Program::getApp()->getMetaNodes()->getNodeIDWithTypeStr(rootIDHint) );

         notifyAsyncAddedNode("", rootIDHint, NODETYPE_Meta); /* (real string ID will
            be retrieved by notifier before sending the heartbeat) */
      }
   }

   return setRootRes;
}

```

客户端在处理与管理节点的心跳信息时，会从中获取并设置元数据 Root 节点信息：

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/client_module/source/common/net/message/nodes/HeartbeatMsgEx.c#L214-245>

```cpp
/**
 * Handles the contained root information.
 */
void __HeartbeatMsgEx_processIncomingRoot(HeartbeatMsgEx* this, App* app)
{
   Logger* log = App_getLogger(app);
   const char* logContext = "Heartbeat incoming (root)";

   NodeStoreEx* metaNodes;
   bool setRootRes;
   NodeOrGroup rootOwner = this->rootIsBuddyMirrored
      ? NodeOrGroup_fromGroup(this->rootNumID.value)
      : NodeOrGroup_fromNode(this->rootNumID);
   NumNodeID rootNumID = HeartbeatMsgEx_getRootNumID(this);

   // check whether root info is defined
   if( (HeartbeatMsgEx_getNodeType(this) != NODETYPE_Meta) || (NumNodeID_isZero(&rootNumID)))
      return;

   // try to apply the contained root info

   metaNodes = App_getMetaNodes(app);

   setRootRes = NodeStoreEx_setRootOwner(metaNodes, rootOwner, false);

   if(setRootRes)
   { // found the very first root
      Logger_logFormatted(log, Log_CRITICAL, logContext, "Root (by Heartbeat): %hu",
         HeartbeatMsgEx_getRootNumID(this).value );
   }

}

```

## 元数据根目录的确定和获取

客户端在挂载文件系统，初始化超级块时，会向元数据 Root 节点获取根目录的 DirEntry 信息：

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/client_module/source/filesystem/FhgfsOpsSuper.c#L253-361>

```cpp
/**
 * Fill the file system superblock (vfs object)
 */
int FhgfsOps_fillSuper(struct super_block* sb, void* rawMountOptions, int silent)
{
   App* app = NULL;
   Config* cfg = NULL;

   struct inode* rootInode;
   struct dentry* rootDentry;
   struct kstat kstat;
   EntryInfo entryInfo;

   FhgfsIsizeHints iSizeHints;

   // init per-mount app object

   if(__FhgfsOps_constructFsInfo(sb, rawMountOptions) )
      return -ECANCELED;

   app = FhgfsOps_getApp(sb);
   cfg = App_getConfig(app);

   // set up super block data

   sb->s_maxbytes = MAX_LFS_FILESIZE;
   sb->s_blocksize = PAGE_SIZE;
   sb->s_blocksize_bits = PAGE_SHIFT;
   sb->s_magic = BEEGFS_MAGIC;
   sb->s_op = &fhgfs_super_ops;
   sb->s_time_gran = 1000000000; // granularity of c/m/atime in ns
#ifdef KERNEL_HAS_SB_NODIRATIME
   sb->s_flags |= SB_NODIRATIME;
#else
   sb->s_flags |= MS_NODIRATIME;
#endif

   if (Config_getSysXAttrsEnabled(cfg ) )
      sb->s_xattr = fhgfs_xattr_handlers_noacl; // handle only user xattrs

#ifdef KERNEL_HAS_POSIX_GET_ACL
   if (Config_getSysACLsEnabled(cfg) )
   {
      sb->s_xattr = fhgfs_xattr_handlers; // replace with acl-capable xattr handlers
#ifdef SB_POSIXACL
      sb->s_flags |= SB_POSIXACL;
#else
      sb->s_flags |= MS_POSIXACL;
#endif
   }
#endif // KERNEL_HAS_POSIX_GET_ACL

   /* MS_ACTIVE is rather important as it marks the super block being successfully initialized and
    * allows the vfs to keep important inodes in the cache. However, it seems it is already
    * initialized in vfs generic mount functions.
      sb->s_flags |= MS_ACTIVE; // used in iput_final()  */

   // NFS kernel export is probably not worth the backport efforts for kernels before 2.6.29
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,29)
   sb->s_export_op = &fhgfs_export_ops;
#endif

#if defined(KERNEL_HAS_SB_BDI)
   sb->s_bdi = FhgfsOps_getBdi(sb);
#endif

   // init root inode

   memset(&kstat, 0, sizeof(struct kstat) );

   kstat.ino = BEEGFS_INODE_ROOT_INO;
   kstat.mode = S_IFDIR | 0777; // allow access for everyone
   kstat.atime = kstat.mtime = kstat.ctime = current_fs_time(sb);
   kstat.uid = current_fsuid();
   kstat.gid = current_fsgid();
   kstat.blksize = Config_getTuneInodeBlockSize(cfg);
   kstat.nlink = 1;

   // root entryInfo is always updated when someone asks for it (so we just set dummy values here)
   EntryInfo_init(&entryInfo, NodeOrGroup_fromGroup(0), StringTk_strDup(""), StringTk_strDup(""),
      StringTk_strDup(""), DirEntryType_DIRECTORY, 0);

   rootInode = __FhgfsOps_newInode(sb, &kstat, 0, &entryInfo, &iSizeHints);
   if(!rootInode || IS_ERR(rootInode) )
   {
      __FhgfsOps_destructFsInfo(sb);
      return IS_ERR(rootInode) ? PTR_ERR(rootInode) : -ENOMEM;
   }

   rootDentry = d_make_root(rootInode);
   if(!rootDentry)
   {
      __FhgfsOps_destructFsInfo(sb);
      return -ENOMEM;
   }

#ifdef KERNEL_HAS_S_D_OP
   // linux 2.6.38 switched from individual per-dentry to defaul superblock d_ops.
   /* note: Only set default dentry operations here, as we don't want those OPs set for the root
    * dentry. In fact, setting as before would only slow down everything a bit, due to
    * useless revalidation of our root dentry. */
   sb->s_d_op = &fhgfs_dentry_ops;
#endif // KERNEL_HAS_S_D_OP

   rootDentry->d_time = jiffies;
   sb->s_root = rootDentry;

   return 0;
}
```

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/client_module/source/common/toolkit/MetadataTk.c#L50-70>

```cpp
/**
 * @param outEntryInfo contained values will be kalloced (on success) and need to be kfreed with
 * FhgfsInode_freeEntryMinInfoVals() later.
 */
bool MetadataTk_getRootEntryInfoCopy(App* app, EntryInfo* outEntryInfo)
{
   NodeStoreEx* nodes = App_getMetaNodes(app);

   NodeOrGroup rootOwner = NodeStoreEx_getRootOwner(nodes);
   const char* parentEntryID = StringTk_strDup("");
   const char* entryID = StringTk_strDup(META_ROOTDIR_ID_STR);
   const char* dirName = StringTk_strDup("");
   DirEntryType entryType = (DirEntryType) DirEntryType_DIRECTORY;

   /* Even if rootOwner is invalid, we still init outEntryInfo and malloc as FhGFS
    * policy says that kfree(NULL) is not allowed (the kernel allows it). */

   EntryInfo_init(outEntryInfo, rootOwner, parentEntryID, entryID, dirName, entryType, 0);

   return NodeOrGroup_valid(rootOwner);
}

```

元数据节点在初始化时，会先后在 BuddyMirror 和非 BuddyMirror 目录查找 ID 名为 root 的根目录 DirEntry 文件：

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/client_module/source/common/storage/Metadata.h#L7>

```cpp
#define META_ROOTDIR_ID_STR            "root"
```

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/meta/source/app/App.cpp#L708-774>

```cpp
void App::initRootDir(NumNodeID localNodeNumID)
{
   // try to load root dir from disk (through metaStore) or create a new one

   this->metaStore = new MetaStore();

   // try to reference root directory with buddy mirroring
   rootDir = this->metaStore->referenceDir(META_ROOTDIR_ID_STR, true, true);

   // if that didn't work try to reference non-buddy-mirrored root dir
   if (!rootDir)
   {
      rootDir = this->metaStore->referenceDir(META_ROOTDIR_ID_STR, false, true);
   }

   if(rootDir)
   { // loading succeeded (either with or without mirroring => init rootNodeID
      this->log->log(Log_NOTICE, "Root directory loaded.");

      NumNodeID rootDirOwner = rootDir->getOwnerNodeID();
      bool rootIsBuddyMirrored = rootDir->getIsBuddyMirrored();

      // try to set rootDirOwner as root node
      if (rootDirOwner && metaRoot.setIfDefault(rootDirOwner, rootIsBuddyMirrored))
      { // new root node accepted (check if rootNode is localNode)
         NumNodeID primaryRootDirOwner;
         if (rootIsBuddyMirrored)
            primaryRootDirOwner = NumNodeID(
               metaBuddyGroupMapper->getPrimaryTargetID(rootDirOwner.val() ) );
         else
            primaryRootDirOwner = rootDirOwner;

         if(localNodeNumID == primaryRootDirOwner)
         {
            log->log(Log_CRITICAL, "I got root (by possession of root directory)");
            if (rootIsBuddyMirrored)
               log->log(Log_CRITICAL, "Root directory is mirrored");
         }
         else
            log->log(Log_CRITICAL,
               "Root metadata server (by possession of root directory): " + rootDirOwner.str());
      }
   }
   else
   { // failed to load root directory => create a new rootDir (not mirrored)
      this->log->log(Log_CRITICAL,
         "This appears to be a new storage directory. Creating a new root dir.");

      UInt16Vector stripeTargets;
      unsigned defaultChunkSize = this->cfg->getTuneDefaultChunkSize();
      unsigned defaultNumStripeTargets = this->cfg->getTuneDefaultNumStripeTargets();
      Raid0Pattern stripePattern(defaultChunkSize, stripeTargets, defaultNumStripeTargets);

      DirInode newRootDir(META_ROOTDIR_ID_STR,
         S_IFDIR | S_IRWXU | S_IRWXG | S_IRWXO, 0, 0, NumNodeID(), stripePattern, false);

      this->metaStore->makeDirInode(newRootDir);
      this->rootDir = this->metaStore->referenceDir(META_ROOTDIR_ID_STR, false, true);

      if(!this->rootDir)
      { // error
         this->log->logErr("Failed to store root directory. Unable to proceed.");
         throw InvalidConfigException("Failed to store root directory");
      }
   }

}
```

## 元数据 ID 文件命名规则

每个目录或者文件都会有一个 ID 文件，而这个 ID 文件的名字组成结构为 `<counterPart>-<timestampPart>-<localNodeID>`

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/common/source/common/toolkit/SessionTk.h#L9-80>

```
class SessionTk
{
   public:

   private:
      SessionTk() {}

   public:
      // inliners

      /**
       * note: fileHandleID format: <ownerFDHex>#<fileID>
       * note2: not supposed to be be on meta servers, use EntryInfo there
       */
      static std::string fileIDFromHandleID(std::string fileHandleID)
      {
         std::string::size_type divPos = fileHandleID.find_first_of("#", 0);

         if(unlikely(divPos == std::string::npos) )
         { // this case should never happen
            return fileHandleID;
         }

         return fileHandleID.substr(divPos + 1);
      }

      /**
       * note: fileHandleID format: <ownerFDHex>#<fileID>
       */
      static unsigned ownerFDFromHandleID(std::string fileHandleID)
      {
         std::string::size_type divPos = fileHandleID.find_first_of("#", 0);

         if(unlikely(divPos == std::string::npos) )
         { // this case should never happen
            return 0;
         }

         std::string ownerFDStr = fileHandleID.substr(0, divPos);

         return StringTk::strHexToUInt(ownerFDStr);
      }

      /**
       * note: fileHandleID format: <ownerFDHex>#<fileID>
       */
      static std::string generateFileHandleID(unsigned ownerFD, std::string fileID)
      {
         return StringTk::uintToHexStr(ownerFD) + '#' + fileID;
      }

      static int sysOpenFlagsFromFhgfsAccessFlags(unsigned accessFlags)
      {
         int openFlags = O_LARGEFILE;

         if(accessFlags & OPENFILE_ACCESS_READWRITE)
            openFlags |= O_RDWR;
         else
         if(accessFlags & OPENFILE_ACCESS_WRITE)
            openFlags |= O_WRONLY;
         else
            openFlags |= O_RDONLY;

         if(accessFlags & OPENFILE_ACCESS_DIRECT)
            openFlags |= O_DIRECT;

         if(accessFlags & OPENFILE_ACCESS_SYNC)
            openFlags |= O_SYNC;

         return openFlags;
      }
};

```

## 元数据组织结构测试

### 清空和查看数据目录

```bash
# 清空文件
rm /mnt/beegfs/* -rf

# 查看剩余的文件
find \
  /beegfs/meta/{inodes,dentries} \
  /beegfs/meta/buddymir/{inodes,dentries} \
  -type f
```

结果如下：

```bash
# beegfs-node1
/beegfs/meta/inodes/38/51/root
/beegfs/meta/inodes/35/5B/disposal
/beegfs/meta/buddymir/inodes/23/40/mdisposal
/beegfs/meta/buddymir/inodes/38/51/root

# beegfs-node2
/beegfs/meta/inodes/35/5B/disposal
/beegfs/meta/buddymir/inodes/38/51/root
/beegfs/meta/buddymir/inodes/23/40/mdisposal
```

### 创建和查看空文件

创建空文件

```bash
touch /mnt/beegfs/test001
```

查看创建后的文件

```bash
> find \
   /beegfs/meta/{inodes,dentries} \
   /beegfs/meta/buddymir/{inodes,dentries} \
   -type f
/beegfs/meta/inodes/38/51/root
/beegfs/meta/inodes/35/5B/disposal
/beegfs/meta/buddymir/inodes/23/40/mdisposal
/beegfs/meta/buddymir/inodes/38/51/root
/beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F656-2
/beegfs/meta/buddymir/dentries/38/51/root/test001
```

查看 inode

```bash
> ls -al -i /beegfs/meta/buddymir/dentries/38/51/root/test001
3151075 -rw-r--r-- 2 root root 0 Jul  4 18:38 /beegfs/meta/buddymir/dentries/38/51/root/test001

> ls -al -i /beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F656-2
3151075 -rw-r--r-- 2 root root 0 Jul  4 18:38 /beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F656-2
```

再次创建文件

```bash
touch /mnt/beegfs/test002
```

查看文件和 inode

```bash
> find \
   /beegfs/meta/{inodes,dentries} \
   /beegfs/meta/buddymir/{inodes,dentries} \
   -type f
/beegfs/meta/inodes/38/51/root
/beegfs/meta/inodes/35/5B/disposal
/beegfs/meta/buddymir/inodes/23/40/mdisposal
/beegfs/meta/buddymir/inodes/38/51/root
/beegfs/meta/buddymir/dentries/38/51/root/test002
/beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F692-2
/beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F656-2
/beegfs/meta/buddymir/dentries/38/51/root/test001

> ls -al -i /beegfs/meta/buddymir/dentries/38/51/root/test002
3151076 -rw-r--r-- 2 root root 0 Jul  4 18:39 /beegfs/meta/buddymir/dentries/38/51/root/test002

> ls -al -i /beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F692-2
3151076 -rw-r--r-- 2 root root 0 Jul  4 18:39 /beegfs/meta/buddymir/dentries/38/51/root/#fSiDs#/0-64A3F692-2
```

### 创建和查看一级目录

创建目录

```bash
mkdir /mnt/beegfs/dir001
```

查看创建目录后的元数据信息

```bash
> find \
   /beegfs/meta/{inodes,dentries} \
   /beegfs/meta/buddymir/{inodes,dentries} \
   -type f
/beegfs/meta/inodes/38/51/root
/beegfs/meta/inodes/35/5B/disposal
/beegfs/meta/buddymir/inodes/23/40/mdisposal
/beegfs/meta/buddymir/inodes/38/51/root
/beegfs/meta/buddymir/inodes/77/78/0-64A3F6D1-2
/beegfs/meta/buddymir/dentries/38/51/root/dir001
```

### 创建和查看非空文件

```bash
dd if=/dev/zero of=/mnt/beegfs/test00 bs=1K count=1

dd if=/dev/zero of=/mnt/beegfs/test00 bs=1K count=1024

dd if=/dev/zero of=/mnt/beegfs/test00 bs=1K count=4096

dd if=/dev/zero of=/mnt/beegfs/test00 bs=1K count=16384

dd if=/dev/zero of=/mnt/beegfs/test00 bs=1K count=65536

```

### 创建和查看多级目录

```bash
touch /mnt/beegfs/dir001/test005

mkdir /mnt/beegfs/dir002

mkdir /mnt/beegfs/dir001/dir003

mkdir /mnt/beegfs/dir001/dir003/dir004

mkdir /mnt/beegfs/dir001/dir003/dir004/dir005/dir006

mkdir /mnt/beegfs/dir001/dir003/dir004/dir005/dir006/dir007

touch /mnt/beegfs/dir001/dir003/dir004/dir005/dir006/test008

touch /mnt/beegfs/dir001/dir003/dir004/dir005/dir006/dir007/test009

```



### 总结

- 对于每个文件，在其 dentries 父目录的 ID 目录中有一个同名的 DirEntry 文件，以及 `#fSiDs#` 子目录中的以 ID 为名称的硬链接；

- 对于每个目录，在其 dentries 父目录的 ID 目录中有一个同名的 DirEntry 文件，以及 inodes 目录中的以 ID 为名称的 DirInode 文件；
- 如果一个目录和其父目录不在一个元数据节点，则其 DirEntry 文件在父目录所在节点，其 DirInode 文件在其被真正存储的节点；
- 无论是 inodes 还是 dentry 目录，里面都是有两级 Hash 目录，每一级有 128 个，根据 DirEntry 和 DirInode 的 ID 进行 Hash。而 ID 文件是根据时间戳生成，所以理论上可以做到很好的均衡。而根目录的 ID 固定为 root，所以总是在 `38/51` 这个 Hash 目录中

## 多元数据节点的分配

在元数据节点每次创建目录时，如果有多个元数据节点，优先选择剩余空间容量多的：

<https://git.beegfs.io/pub/v7/-/blame/7.3.3/meta/source/net/message/storage/creating/MkDirMsgEx.cpp#L61>

```cpp
std::unique_ptr<MkDirMsgEx::ResponseState> MkDirMsgEx::mkDirPrimary(ResponseContext& ctx)
{
   // ...
   NodeCapacityPools* metaCapacityPools;
   // ...
   if (isBuddyMirrored)
      metaCapacityPools = app->getMetaBuddyCapacityPools();
   else
      metaCapacityPools = app->getMetaCapacityPools();
   // ...
   metaCapacityPools->chooseStorageTargets(numDesiredTargets, minNumRequiredTargets,
                                           &getPreferredNodes(), &newOwnerNodes);
   // ...
}
```

<https://git.beegfs.io/pub/v7/-/blob/7.3.3/common/source/common/nodes/NodeCapacityPools.cpp#L205-292>

```cpp
/**
 * @param numTargets number of desired targets
 * @param minNumRequiredTargets the minimum number of targets the caller needs; ususally 1
 * for RAID-0 striping and 2 for mirroring (so this parameter is intended to avoid problems when
 * there is only 1 target left in the normal pool and the user has mirroring turned on).
 * @param preferredTargets may be NULL
 */
void NodeCapacityPools::chooseStorageTargets(unsigned numTargets, unsigned minNumRequiredTargets,
   const UInt16List* preferredTargets, UInt16Vector* outTargets)
{
   RWLockGuard lock(rwlock, SafeRWLock_READ);

   if(!preferredTargets || preferredTargets->empty() )
   { // no preference => start with first pool that contains any targets
      if (!pools[CapacityPool_NORMAL].empty())
      {
         chooseStorageNodesNoPref(pools[CapacityPool_NORMAL], numTargets, outTargets);

         if(outTargets->size() >= minNumRequiredTargets)
            return;
      }

      /* note: no "else if" here, because we want to continue with next pool if we didn't find
         enough targets for minNumRequiredTargets in previous pool */

      if (!pools[CapacityPool_LOW].empty())
      {
         chooseStorageNodesNoPref(pools[CapacityPool_LOW], numTargets - outTargets->size(),
                                  outTargets);

         if(outTargets->size() >= minNumRequiredTargets)
            return;
      }

      chooseStorageNodesNoPref(pools[CapacityPool_EMERGENCY], numTargets, outTargets);
   }
   else
   {
      // caller has preferred targets, so we can't say a priori whether nodes will be found or not
      // in a pool. our strategy here is to automatically allow non-preferred targets before
      // touching the emergency pool.

      std::set<uint16_t> chosenTargets;

      // try normal and low pool with preferred targets...

      chooseStorageNodesWithPref(pools[CapacityPool_NORMAL], numTargets, preferredTargets, false,
                                 outTargets, chosenTargets);

      if(outTargets->size() >= minNumRequiredTargets)
         return;

      chooseStorageNodesWithPref(pools[CapacityPool_LOW], numTargets - outTargets->size(),
                                 preferredTargets, false, outTargets, chosenTargets);

      if(!outTargets->empty() )
         return;

      /* note: currently, we cannot just continue here with non-empty outTargets (even if
         "outTargets->size() < minNumRequiredTargets"), because we would need a mechanism to exclude
         the already chosen outTargets for that (e.g. like an inverted preferredTargets list). */

      // no targets yet - allow non-preferred targets before using emergency pool...

      chooseStorageNodesWithPref(pools[CapacityPool_NORMAL], numTargets, preferredTargets, true,
                                 outTargets, chosenTargets);

      if(outTargets->size() >= minNumRequiredTargets)
         return;

      chooseStorageNodesWithPref(pools[CapacityPool_LOW], numTargets - outTargets->size(),
                                 preferredTargets, true, outTargets, chosenTargets);

      if(!outTargets->empty() )
         return;

      /* still no targets available => we have to try the emergency pool (first with preference,
         then without preference) */

      chooseStorageNodesWithPref(pools[CapacityPool_EMERGENCY], numTargets, preferredTargets, false,
         outTargets, chosenTargets);
      if(!outTargets->empty() )
         return;

      chooseStorageNodesWithPref(pools[CapacityPool_EMERGENCY], numTargets, preferredTargets, true,
         outTargets, chosenTargets);
   }
}
```

相关的配置选项和说明如下：

- `/etc/beegfs/beegfs-client.conf`

```ini
tunePreferredMetaFile         =
tunePreferredStorageFile      =

# [tunePreferredMetaFile], [tunePreferredStorageFile]
# Path to a text file that contains the numeric IDs of preferred storage targets
# and metadata servers. These will be preferred when the client creates new file
# system entries. This is useful e.g. to take advantage of data locality in the
# case of multiple data centers. If unspecified, all available targets and
# servers will be used equally.
# Usage: One targetID per line for storage servers, one nodeID per line for
#    metadata servers.
# Note: TargetIDs and nodeIDs can be queried with the beegfs-ctl tool.
# Default: <none>
```

- `/etc/beegfs/beegfs-mgmtd.conf`

```ini
tuneMetaDynamicPools                   = true
tuneMetaInodesLowLimit                 = 10M
tuneMetaInodesEmergencyLimit           = 1M
tuneMetaSpaceLowLimit                  = 10G
tuneMetaSpaceEmergencyLimit            = 3G
tuneStorageDynamicPools                = true
tuneStorageInodesLowLimit              = 10M
tuneStorageInodesEmergencyLimit        = 1M
tuneStorageSpaceLowLimit               = 1T
tuneStorageSpaceEmergencyLimit         = 20G

# [tune{Meta,Storage}DynamicPools]
# Temporarily raise the Low/Emergency limits if the spread (difference in free
# capacity between the targets with the most and the least free space) becomes
# too large. This will move targets to a lower pool earlier if there are other
# targets with much more free capacity.

# [tune{Meta,Storage}{Space,Inodes}LowLimit]
# [tune{Meta,Storage}{Space,Inodes}EmergencyLimit]
# The free space pool thresholds. If a metadata or storage target is below a
# threshold, it will only be used to store new files and directories when no
# higher class targets are available (i.e. while there are targets in the
# "normal" pool, no targets from the "low" pool will be used.)
# Note: Preferred target settings of a client will be ignored if it helps to
#    avoid using targets from the emergency class.
# Default: Space: Meta: 10G/3G; Storage: 512G/10G
#          Inodes: Meta: 10M/1M; Storage: 10M/1M

# [tune{Meta,Storage}{Space,Inodes}NormalSpreadThreshold]
# [tune{Meta,Storage}{Space,Inodes}LowSpreadThreshold]
# [tune{Meta,Storage}{Space,Inodes}LowDynamicLimit]
# [tune{Meta,Storage}{Space,Inodes}EmergencyDynamicLimit]
# Only effective if tune{Meta,Storage}DynamicPools is enabled.
# Whenever the spread (see above) of the free capacities in the normal / low
# class of storage targets is above this threshold, the StorageLowLimit /
# StorageEmergencyLimit is temporarily raised to StorageLowDynamicLimit /
# StorageEmergencyDynamicLimit.
# When the {Normal,Low}SpreadThreshold values are set to 0, the value from the
# corresponding {Low,Emergency}Limit is used for the spread threshold.
# When the {Low,Emergency}DynamicLimits are set to 0, they are automatically
# assumed as two times the corresponding {Low,Emergency}(non-dynamic)Limit.
# Default: 0
```

