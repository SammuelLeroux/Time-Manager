export interface Users {
  id?: number | undefined;
  username?: string | undefined;
  email?: string | undefined;
}

export interface TeamMembers {
  id?: number | undefined;
  username?: string | undefined;
}

export interface Clocks {
  id?: number | undefined;
  status?: boolean | undefined;
  start_time?: Date | undefined;
  end_time?: Date | undefined;
}

export interface WorkingTimes {
  id?: number | undefined;
  start?: Date | undefined;
  end?: Date | undefined;
}

export interface DecodedToken {
  user_id?: number;
  role?: string;
  team_id?: number;
  is_google_user?: string | boolean
}
