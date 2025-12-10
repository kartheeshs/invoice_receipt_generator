'use client';

import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslation } from '../../lib/i18n';
import {
  ADMIN_USERS_STORAGE_KEY,
  adminUsersSeed,
  createAdminUserId,
  loadAdminUsers,
  persistAdminUsers,
  type AdminUser,
  type AdminUserRole,
  type AdminUserStatus,
} from '../../lib/admin';
import { formatFriendlyDate } from '../../lib/format';
import { loadSession, SESSION_STORAGE_KEY, type StoredSession } from '../../lib/auth';

type UserFormState = {
  id?: string;
  name: string;
  email: string;
  role: AdminUserRole;
  status: AdminUserStatus;
};

const EMPTY_USER_FORM: UserFormState = {
  id: undefined,
  name: '',
  email: '',
  role: 'member',
  status: 'invited',
};

export default function ManageUsersView(): JSX.Element {
  const { t, locale } = useTranslation();
  const pathname = usePathname();
  const [users, setUsers] = useState<AdminUser[]>(adminUsersSeed);
  const [search, setSearch] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<'all' | AdminUserRole>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | AdminUserStatus>('all');
  const [selectedUserId, setSelectedUserId] = useState<string | 'new' | null>(null);
  const [formState, setFormState] = useState<UserFormState>(EMPTY_USER_FORM);
  const [statusNotice, setStatusNotice] = useState<{ type: 'idle' | 'success' | 'error'; message: string }>({
    type: 'idle',
    message: '',
  });
  const [session, setSession] = useState<StoredSession | null>(null);
  const [checkingSession, setCheckingSession] = useState<boolean>(true);

  const updateUsers = useCallback(
    (updater: AdminUser[] | ((entries: AdminUser[]) => AdminUser[])) => {
      setUsers((current) => {
        const next =
          typeof updater === 'function'
            ? (updater as (entries: AdminUser[]) => AdminUser[])(current)
            : updater;
        persistAdminUsers(next);
        return next;
      });
    },
    [],
  );

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const loaded = loadAdminUsers();
    setUsers(loaded.length ? loaded : adminUsersSeed);

    const handleStorage = (event: StorageEvent) => {
      if (event.key === ADMIN_USERS_STORAGE_KEY) {
        const refreshed = loadAdminUsers();
        setUsers(refreshed.length ? refreshed : adminUsersSeed);
      }
    };

    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const applySession = () => {
      const current = loadSession();
      setSession(current);
      setCheckingSession(false);
    };

    applySession();

    const handleStorage = (event: StorageEvent) => {
      if (event.key === SESSION_STORAGE_KEY) {
        applySession();
      }
    };

    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  useEffect(() => {
    if (!selectedUserId) {
      if (users.length) {
        setSelectedUserId(users[0].id);
      }
      return;
    }

    if (selectedUserId === 'new') {
      setFormState(EMPTY_USER_FORM);
      return;
    }

    const match = users.find((entry) => entry.id === selectedUserId);
    if (match) {
      setFormState({
        id: match.id,
        name: match.name,
        email: match.email,
        role: match.role,
        status: match.status,
      });
    }
  }, [selectedUserId, users]);

  const filteredUsers = useMemo(() => {
    const query = search.trim().toLowerCase();
    return users.filter((user) => {
      if (roleFilter !== 'all' && user.role !== roleFilter) {
        return false;
      }
      if (statusFilter !== 'all' && user.status !== statusFilter) {
        return false;
      }
      if (!query) {
        return true;
      }
      return (
        user.name.toLowerCase().includes(query) || user.email.toLowerCase().includes(query)
      );
    });
  }, [users, search, roleFilter, statusFilter]);

  const selectedUser = useMemo(() => {
    if (!selectedUserId || selectedUserId === 'new') {
      return null;
    }
    return users.find((entry) => entry.id === selectedUserId) ?? null;
  }, [selectedUserId, users]);

  function handleSelectUser(id: string) {
    setSelectedUserId(id);
    setStatusNotice({ type: 'idle', message: '' });
  }

  function handleCreateUser() {
    setSelectedUserId('new');
    setFormState(EMPTY_USER_FORM);
    setStatusNotice({ type: 'idle', message: '' });
  }

  function handleFormChange(field: keyof UserFormState, value: string) {
    setFormState((prev) => ({ ...prev, [field]: value }));
    if (statusNotice.type !== 'idle') {
      setStatusNotice({ type: 'idle', message: '' });
    }
  }

  function handleUserSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmedName = formState.name.trim();
    const trimmedEmail = formState.email.trim().toLowerCase();

    if (!trimmedName || !trimmedEmail) {
      setStatusNotice({
        type: 'error',
        message: t('admin.manage.errorRequired', 'Enter both a name and email to continue.'),
      });
      return;
    }

    const duplicate = users.some(
      (user) =>
        user.email.toLowerCase() === trimmedEmail &&
        user.id !== (formState.id ?? selectedUser?.id ?? ''),
    );

    if (duplicate) {
      setStatusNotice({
        type: 'error',
        message: t('admin.manage.errorDuplicate', 'That email address already belongs to another user.'),
      });
      return;
    }

    const payload: AdminUser = {
      id: formState.id ?? createAdminUserId(),
      name: trimmedName,
      email: trimmedEmail,
      role: formState.role,
      status: formState.status,
      lastActive: selectedUser?.lastActive ?? t('admin.manage.status.new', 'Never active'),
      createdAt: selectedUser?.createdAt ?? new Date().toISOString(),
    };

    updateUsers((current) => {
      const existingIndex = current.findIndex((entry) => entry.id === payload.id);
      if (existingIndex >= 0) {
        const copy = current.slice();
        copy.splice(existingIndex, 1, payload);
        return copy;
      }
      return [payload, ...current];
    });

    setSelectedUserId(payload.id);
    setStatusNotice({
      type: 'success',
      message: selectedUser
        ? t('admin.manage.updated', 'User details updated successfully.')
        : t('admin.manage.created', 'User invitation recorded.'),
    });
  }

  function handleDeleteUser() {
    if (!selectedUser) {
      return;
    }
    if (selectedUser.role === 'owner') {
      setStatusNotice({
        type: 'error',
        message: t('admin.manage.errorOwner', 'The workspace owner cannot be removed.'),
      });
      return;
    }

    const remainingUsers = users.filter((user) => user.id !== selectedUser.id);
    updateUsers(remainingUsers);
    setSelectedUserId(remainingUsers[0]?.id ?? null);
    setStatusNotice({
      type: 'success',
      message: t('admin.manage.removed', 'User removed from the admin workspace.'),
    });
  }

  const noticeClass =
    statusNotice.type === 'idle'
      ? 'admin-manage__notice'
      : `admin-manage__notice admin-manage__notice--${statusNotice.type}`;

  const createdLabel = selectedUser
    ? formatFriendlyDate(new Date(selectedUser.createdAt).toISOString(), locale)
    : '';

  const loginHref = useMemo(() => {
    if (!pathname) {
      return '/admin/login';
    }
    const nextParam = encodeURIComponent(pathname);
    return `/admin/login?next=${nextParam}`;
  }, [pathname]);

  if (checkingSession) {
    return (
      <section className="admin-manage admin-manage--access" aria-busy="true">
        <div className="admin-manage__access admin-manage__access--loading">
          <div className="admin-manage__spinner" aria-hidden="true" />
          <h1>{t('admin.manage.authChecking', 'Checking your administrator access…')}</h1>
          <p>{t('admin.manage.authCheckingHint', 'Hold tight while we confirm your session.')}</p>
        </div>
      </section>
    );
  }

  if (!session || session.role !== 'admin') {
    return (
      <section className="admin-manage admin-manage--access">
        <div className="admin-manage__access">
          <h1>{t('admin.manage.authRequired', 'Administrator access required')}</h1>
          <p>
            {t(
              'admin.manage.authRequiredHint',
              'Sign in with an administrator account to invite teammates and manage workspace roles.',
            )}
          </p>
          <div className="admin-manage__access-actions">
            <Link className="button button--primary" href={loginHref} prefetch={false}>
              {t('admin.manage.authRequiredCta', 'Go to admin login')}
            </Link>
            <Link className="button button--ghost" href="/app" prefetch={false}>
              {t('admin.manage.authReturn', 'Back to workspace')}
            </Link>
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="admin-manage">
      <header className="admin-manage__header">
        <div>
          <h1>{t('admin.manage.title', 'Manage users')}</h1>
          <p>
            {t(
              'admin.manage.subtitle',
              'Invite teammates, promote administrators, and keep your billing workspace secure.',
            )}
          </p>
        </div>
        <Link className="button button--ghost" href="/admin/console" prefetch={false}>
          {t('admin.manage.openConsole', 'Open monitoring console')}
        </Link>
      </header>

      <div className="admin-manage__toolbar">
        <input
          type="search"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t('admin.manage.searchPlaceholder', 'Search by name or email')}
        />
        <div className="admin-manage__filters">
          <label>
            <span>{t('admin.manage.roleFilter', 'Role')}</span>
            <select value={roleFilter} onChange={(event) => setRoleFilter(event.target.value as typeof roleFilter)}>
              <option value="all">{t('admin.manage.roleAll', 'All roles')}</option>
              <option value="owner">{t('admin.manage.roleOwner', 'Owner')}</option>
              <option value="admin">{t('admin.manage.roleAdmin', 'Admin')}</option>
              <option value="member">{t('admin.manage.roleMember', 'Member')}</option>
            </select>
          </label>
          <label>
            <span>{t('admin.manage.statusFilter', 'Status')}</span>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value as typeof statusFilter)}
            >
              <option value="all">{t('admin.manage.statusAll', 'All statuses')}</option>
              <option value="active">{t('admin.manage.statusActive', 'Active')}</option>
              <option value="invited">{t('admin.manage.statusInvited', 'Invited')}</option>
              <option value="suspended">{t('admin.manage.statusSuspended', 'Suspended')}</option>
            </select>
          </label>
        </div>
        <button type="button" className="button button--primary" onClick={handleCreateUser}>
          ➕ {t('admin.manage.invite', 'Invite user')}
        </button>
      </div>

      <div className="admin-manage__layout">
        <aside className="admin-manage__list">
          {filteredUsers.length ? (
            <ul>
              {filteredUsers.map((user) => {
                const active = user.id === selectedUserId;
                return (
                  <li key={user.id}>
                    <button
                      type="button"
                      className={`admin-manage__list-button${active ? ' admin-manage__list-button--active' : ''}`}
                      onClick={() => handleSelectUser(user.id)}
                    >
                      <strong>{user.name}</strong>
                      <span>{user.email}</span>
                      <div className="admin-manage__list-meta">
                        <span>{t(`admin.manage.role.${user.role}`, user.role)}</span>
                        <span>{t(`admin.manage.status.${user.status}`, user.status)}</span>
                      </div>
                    </button>
                  </li>
                );
              })}
            </ul>
          ) : (
            <div className="admin-manage__empty">
              {t('admin.manage.noMatches', 'No users match your filters.')}
            </div>
          )}
        </aside>

        <section className="admin-manage__detail">
          {statusNotice.message && <div className={noticeClass}>{statusNotice.message}</div>}

          {selectedUserId === 'new' ? (
            <form className="admin-manage__form" onSubmit={handleUserSubmit} noValidate>
              <header>
                <h2>{t('admin.manage.formTitleInvite', 'Invite a new user')}</h2>
                <p>
                  {t('admin.manage.formSubtitleInvite', 'Send credentials to teammates who need access to the billing workspace.')}
                </p>
              </header>
              <div className="admin-manage__form-grid">
                <label>
                  <span>{t('admin.manage.nameLabel', 'Full name')}</span>
                  <input
                    type="text"
                    value={formState.name}
                    onChange={(event) => handleFormChange('name', event.target.value)}
                    placeholder={t('admin.manage.namePlaceholder', 'Jordan Carter')}
                    required
                  />
                </label>
                <label>
                  <span>{t('admin.manage.emailLabel', 'Email')}</span>
                  <input
                    type="email"
                    value={formState.email}
                    onChange={(event) => handleFormChange('email', event.target.value)}
                    placeholder={t('admin.manage.emailPlaceholder', 'user@company.com')}
                    required
                  />
                </label>
                <label>
                  <span>{t('admin.manage.roleLabel', 'Role')}</span>
                  <select
                    value={formState.role}
                    onChange={(event) => handleFormChange('role', event.target.value as AdminUserRole)}
                  >
                    <option value="member">{t('admin.manage.roleMember', 'Member')}</option>
                    <option value="admin">{t('admin.manage.roleAdmin', 'Admin')}</option>
                  </select>
                </label>
                <label>
                  <span>{t('admin.manage.statusLabel', 'Status')}</span>
                  <select
                    value={formState.status}
                    onChange={(event) => handleFormChange('status', event.target.value as AdminUserStatus)}
                  >
                    <option value="invited">{t('admin.manage.statusInvited', 'Invited')}</option>
                    <option value="active">{t('admin.manage.statusActive', 'Active')}</option>
                  </select>
                </label>
              </div>
              <div className="admin-manage__form-actions">
                <button type="button" className="button button--ghost" onClick={() => setSelectedUserId(users[0]?.id ?? null)}>
                  {t('admin.manage.cancel', 'Cancel')}
                </button>
                <button type="submit" className="button button--primary">
                  {t('admin.manage.sendInvite', 'Send invite')}
                </button>
              </div>
            </form>
          ) : selectedUser ? (
            <form className="admin-manage__form" onSubmit={handleUserSubmit} noValidate>
              <header>
                <h2>{t('admin.manage.formTitleEdit', 'User details')}</h2>
                <p>
                  {t('admin.manage.formSubtitleEdit', 'Update access levels, or deactivate an account if someone leaves the team.')}
                </p>
              </header>
              <div className="admin-manage__form-grid">
                <label>
                  <span>{t('admin.manage.nameLabel', 'Full name')}</span>
                  <input
                    type="text"
                    value={formState.name}
                    onChange={(event) => handleFormChange('name', event.target.value)}
                    required
                  />
                </label>
                <label>
                  <span>{t('admin.manage.emailLabel', 'Email')}</span>
                  <input
                    type="email"
                    value={formState.email}
                    onChange={(event) => handleFormChange('email', event.target.value)}
                    required
                  />
                </label>
                <label>
                  <span>{t('admin.manage.roleLabel', 'Role')}</span>
                  <select
                    value={formState.role}
                    onChange={(event) => handleFormChange('role', event.target.value as AdminUserRole)}
                    disabled={selectedUser.role === 'owner'}
                  >
                    <option value="owner">{t('admin.manage.roleOwner', 'Owner')}</option>
                    <option value="admin">{t('admin.manage.roleAdmin', 'Admin')}</option>
                    <option value="member">{t('admin.manage.roleMember', 'Member')}</option>
                  </select>
                </label>
                <label>
                  <span>{t('admin.manage.statusLabel', 'Status')}</span>
                  <select
                    value={formState.status}
                    onChange={(event) => handleFormChange('status', event.target.value as AdminUserStatus)}
                  >
                    <option value="active">{t('admin.manage.statusActive', 'Active')}</option>
                    <option value="invited">{t('admin.manage.statusInvited', 'Invited')}</option>
                    <option value="suspended">{t('admin.manage.statusSuspended', 'Suspended')}</option>
                  </select>
                </label>
              </div>
              <div className="admin-manage__meta">
                <div>
                  <strong>{t('admin.manage.joined', 'Joined')}</strong>
                  <span>{createdLabel}</span>
                </div>
                <div>
                  <strong>{t('admin.manage.lastActive', 'Last active')}</strong>
                  <span>{selectedUser.lastActive}</span>
                </div>
              </div>
              <div className="admin-manage__form-actions">
                <button type="button" className="button button--ghost" onClick={handleDeleteUser}>
                  {t('admin.manage.removeUser', 'Remove user')}
                </button>
                <button type="submit" className="button button--primary">
                  {t('admin.manage.saveChanges', 'Save changes')}
                </button>
              </div>
            </form>
          ) : (
            <div className="admin-manage__empty">
              {t('admin.manage.selectPrompt', 'Select a teammate to view their permissions.')}
            </div>
          )}
        </section>
      </div>
    </section>
  );
}
