const FILE_SUPERSEDE = 0x00000000;
const FILE_OPEN = 0x00000001;
const FILE_CREATE = 0x00000002;
const FILE_OPEN_IF = 0x00000003;
const FILE_OVERWRITE = 0x00000004;
const FILE_OVERWRITE_IF = 0x00000005;

const MAX_READ_LENGTH = 0x00010000;
const MAX_WRITE_LENGTH = 0x00010000 - 0x71;

const DELETE = 0x00010000;
const FILE_APPEND_DATA = 0x00000004;
const FILE_DELETE_CHILD = 0x00000040;
const FILE_READ_ATTRIBUTES = 0x00000080;
const FILE_READ_DATA = 0x00000001;
const FILE_READ_EA = 0x00000008;
const FILE_WRITE_ATTRIBUTES = 0x00000100;
const FILE_WRITE_DATA = 0x00000002;
const FILE_WRITE_EA = 0x00000010;
const READ_CONTROL = 0x00020000;
const SYNCHRONIZE = 0x00100000;
const WRITE_DAC = 0x00040000;


const ATTR_READONLY = 0x00000001; // File is read-only. Applications cannot write or delete the file.
const ATTR_HIDDEN = 0x00000002; // File is hidden. It is not to be included in an ordinary directory enumeration.
const ATTR_SYSTEM = 0x00000004; // File is part of or is used exclusively by the operating system.
const ATTR_DIRECTORY = 0x00000010; // File is a directory.
const ATTR_ARCHIVE = 0x00000020; // File has not been archived since it was last modified.
const ATTR_NORMAL = 0x00000080; // File has no other attributes set. This value is valid only when used alone.
const ATTR_TEMPORARY = 0x00000100; // File is temporary.

const ATTR_SPARSE = 0x00000200 ; // Yes File is a sparse file.
const ATTR_REPARSE_POINT = 0x00000400; // Yes File or directory has an associated reparse point.
const ATTR_COMPRESSED = 0x00000800; // No File is compressed on the disk. This does not affect how it is transferred over the network.
const ATTR_OFFLINE = 0x00001000; // Yes File data is not available. The attribute indicates that the file has been moved to offline storage.
const ATTR_NOT_CONTENT_INDEXED = 0x00002000; // Yes File or directory SHOULD NOT be indexed by a content indexing service.
const ATTR_ENCRYPTED = 0x00004000; // Yes File or directory is encrypted. For a file, this means that all data in the file is encrypted. For a directory, this means that encryption is the default for newly created files and subdirectories.


