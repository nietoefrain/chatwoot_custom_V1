import {
  getUserPermissions,
  getUserRole,
} from '../../../helper/permissionsHelper';
import { applyRoleFilter } from '../conversations/helpers';

const INBOX_SORT_OPTIONS = {
  newest: 'desc',
  oldest: 'asc',
};

const sortConfig = {
  newest: (a, b) => b.created_at - a.created_at,
  oldest: (a, b) => a.created_at - b.created_at,
};

export const sortComparator = (a, b, sortOrder) => {
  const sortDirection = INBOX_SORT_OPTIONS[sortOrder];
  if (sortOrder === 'newest' || sortOrder === 'oldest') {
    return sortConfig[sortOrder](a, b, sortDirection);
  }
  return 0;
};

export const isAccessibleNotification = (
  notification,
  currentUser,
  currentAccountId,
  currentAccount
) => {
  if (notification.primary_actor_type !== 'Conversation') {
    return true;
  }

  if (!notification.primary_actor || !currentUser || !currentAccountId) {
    return false;
  }

  const permissions = getUserPermissions(currentUser, currentAccountId);
  const userRole = getUserRole(currentUser, currentAccountId);

  return applyRoleFilter(
    notification.primary_actor,
    userRole,
    permissions,
    currentUser.id,
    currentAccount
  );
};

export const isOwnedInboxNotification = (notification, currentUser) => {
  if (!notification.primary_actor || !currentUser) {
    return false;
  }

  const assigneeId =
    notification.primary_actor.assignee_id ||
    notification.primary_actor.meta?.assignee?.id;

  if (!assigneeId) {
    return true;
  }

  return assigneeId === currentUser.id;
};
