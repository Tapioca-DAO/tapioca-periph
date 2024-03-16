import { scope } from 'hardhat/config';
import { setClusterOnMagnetar__task } from 'tasks/exec/magnetar/magnetar-setCluster';
import { setHelperOnMagnetar__task } from 'tasks/exec/magnetar/magnetar-setHelper';

const magnetarScope = scope('magnetar', 'Magnetar setter tasks');

magnetarScope.task(
    'setClusterOnMagnetar',
    'Sets Cluster address on Magnetar',
    setClusterOnMagnetar__task,
);

magnetarScope.task(
    'setHelperOnMagnetar',
    'Sets MagnetarHelper on Magnetar',
    setHelperOnMagnetar__task,
);
