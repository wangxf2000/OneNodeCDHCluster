DROP DATABASE IF EXISTS scm;
DROP DATABASE IF EXISTS amon;
DROP DATABASE IF EXISTS rman;
DROP DATABASE IF EXISTS hue;
DROP DATABASE IF EXISTS metastore;
DROP DATABASE IF EXISTS sentry;
DROP DATABASE IF EXISTS nav;
DROP DATABASE IF EXISTS navms;
DROP DATABASE IF EXISTS oozie;
DROP DATABASE IF EXISTS efm;
DROP DATABASE IF EXISTS nifireg;
DROP DATABASE IF EXISTS registry;
DROP DATABASE IF EXISTS streamsmsgmgr;
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE efm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON efm.* TO 'efm'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE nifireg DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON nifireg.* TO 'nifireg'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE registry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON registry.* TO 'registry'@'%' IDENTIFIED BY 'Gyzq!123';

CREATE DATABASE streamsmsgmgr DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON streamsmsgmgr.* TO 'streamsmsgmgr'@'%' IDENTIFIED BY 'Gyzq!123';
