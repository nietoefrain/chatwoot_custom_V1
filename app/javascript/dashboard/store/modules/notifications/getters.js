import { sortComparator } from './helpers';
import camelcaseKeys from 'camelcase-keys';
import {
  getUserPermissions,
  getUserRole,
} from '../../../helper/permissionsHelper';
import { applyRoleFilter } from '../conversations/helpers';

const filterAccessibleNotifications = (records, rootGetters) => {
  const currentUser = rootGetters.getCurrentUser;
  const currentAccountId = rootGetters.getCurrentAccountId;
  const currentAccount = rootGetters.getCurrentAccount;
  const currentUserId = currentUser?.id;

  if (!currentUser || !currentAccountId) {
    return records;
  }

  const permissions = getUserPermissions(currentUser, currentAccountId);
  const userRole = getUserRole(currentUser, currentAccountId);

  return records.filter(notification => {
    if (notification.primary_actor_type !== 'Conversation') {
      return true;
    }

    if (!notification.primary_actor) {
      return false;
    }

    return applyRoleFilter(
      notification.primary_actor,
      userRole,
      permissions,
      currentUserId,
      currentAccount
    );
  });
};

export const getters = {
  getNotifications($state, _, __, rootGetters) {
    return filterAccessibleNotifications(
      Object.values($state.records),
      rootGetters
    ).sort((n1, n2) => n2.id - n1.id);
  },
  getFilteredNotifications: ($state, _, __, rootGetters) => filters => {
    const sortOrder = filters.sortOrder === 'desc' ? 'newest' : 'oldest';
    const sortedNotifications = filterAccessibleNotifications(
      Object.values($state.records),
      rootGetters
    ).sort((n1, n2) => sortComparator(n1, n2, sortOrder));
    return sortedNotifications;
  },
  getFilteredNotificationsV4: ($state, _, __, rootGetters) => filters => {
    const sortOrder = filters.sortOrder === 'desc' ? 'newest' : 'oldest';
    const sortedNotifications = filterAccessibleNotifications(
      Object.values($state.records),
      rootGetters
    ).sort((n1, n2) => sortComparator(n1, n2, sortOrder));
    return camelcaseKeys(sortedNotifications, { deep: true });
  },
  getNotificationById: $state => id => {
    return $state.records[id] || {};
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getNotification: $state => id => {
    const notification = $state.records[id];
    return notification || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
  getNotificationFilters($state) {
    return $state.notificationFilters;
  },
  getHasUnreadNotifications: $state => {
    return $state.meta.unreadCount > 0;
  },
  getUnreadCount: $state => {
    return $state.meta.unreadCount;
  },
};
