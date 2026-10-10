from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database.connection import get_db
from identity.auth import authenticate_request, get_or_create_authenticated_profile
from community.models import CommunityComment, CommunityPost, CommunityReport

router = APIRouter(prefix="/community", tags=["community"])


class PostCreateRequest(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


class CommentCreateRequest(BaseModel):
    body: str = Field(min_length=1, max_length=1200)


class ReportCreateRequest(BaseModel):
    reason: Literal["spam", "harassment", "hate_or_abuse", "scam", "misinformation", "other"]
    details: str | None = Field(default=None, max_length=600)


def _profile_identity(claims: dict[str, Any]) -> tuple[str, str]:
    profile = get_or_create_authenticated_profile(claims)
    profile_id = str(profile.get("id") or "").strip()
    if not profile_id:
        raise HTTPException(status_code=401, detail="Authenticated profile could not be loaded.")
    display_name = str(profile.get("name") or claims.get("name") or "SAGE user").strip()
    return profile_id, display_name or "SAGE user"


def _clean(value: str, label: str) -> str:
    result = value.strip()
    if not result:
        raise HTTPException(status_code=422, detail=f"{label} is required.")
    return result


def _timestamp(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def _post_dict(
    post: CommunityPost,
    *,
    current_profile_id: str,
    comment_count: int = 0,
    has_reported: bool = False,
) -> dict[str, Any]:
    return {
        "id": post.id,
        "author_name": post.author_name,
        "body": post.body,
        "created_at": _timestamp(post.created_at),
        "comment_count": comment_count,
        "is_mine": post.profile_id == current_profile_id,
        "has_reported": has_reported,
    }


def _comment_dict(comment: CommunityComment, current_profile_id: str) -> dict[str, Any]:
    return {
        "id": comment.id,
        "post_id": comment.post_id,
        "author_name": comment.author_name,
        "body": comment.body,
        "created_at": _timestamp(comment.created_at),
        "is_mine": comment.profile_id == current_profile_id,
    }


def _active_post(db: Session, post_id: str) -> CommunityPost:
    post = (
        db.query(CommunityPost)
        .filter(CommunityPost.id == post_id, CommunityPost.status == "active")
        .first()
    )
    if post is None:
        raise HTTPException(status_code=404, detail="Community post not found.")
    return post


@router.get("/posts")
def list_community_posts(
    limit: int = Query(default=30, ge=1, le=100),
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, _ = _profile_identity(claims)
    posts = (
        db.query(CommunityPost)
        .filter(CommunityPost.status == "active")
        .order_by(CommunityPost.created_at.desc(), CommunityPost.id.desc())
        .limit(limit)
        .all()
    )
    post_ids = [post.id for post in posts]
    comment_counts: dict[str, int] = {}
    reported_ids: set[str] = set()
    if post_ids:
        rows = (
            db.query(CommunityComment.post_id, func.count(CommunityComment.id))
            .filter(
                CommunityComment.post_id.in_(post_ids),
                CommunityComment.status == "active",
            )
            .group_by(CommunityComment.post_id)
            .all()
        )
        comment_counts = {post_id: count for post_id, count in rows}
        reported_ids = {
            row[0]
            for row in db.query(CommunityReport.post_id)
            .filter(
                CommunityReport.post_id.in_(post_ids),
                CommunityReport.reporter_profile_id == profile_id,
            )
            .all()
        }
    return {
        "success": True,
        "posts": [
            _post_dict(
                post,
                current_profile_id=profile_id,
                comment_count=comment_counts.get(post.id, 0),
                has_reported=post.id in reported_ids,
            )
            for post in posts
        ],
    }


@router.post("/posts", status_code=status.HTTP_201_CREATED)
def create_community_post(
    request: PostCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, author_name = _profile_identity(claims)
    post = CommunityPost(
        id=str(uuid.uuid4()),
        profile_id=profile_id,
        author_name=author_name,
        body=_clean(request.body, "Post text"),
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return {
        "success": True,
        "post": _post_dict(post, current_profile_id=profile_id),
    }


@router.get("/posts/{post_id}/comments")
def list_community_comments(
    post_id: str,
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, _ = _profile_identity(claims)
    _active_post(db, post_id)
    comments = (
        db.query(CommunityComment)
        .filter(
            CommunityComment.post_id == post_id,
            CommunityComment.status == "active",
        )
        .order_by(CommunityComment.created_at.asc(), CommunityComment.id.asc())
        .all()
    )
    return {
        "success": True,
        "comments": [_comment_dict(comment, profile_id) for comment in comments],
    }


@router.post("/posts/{post_id}/comments", status_code=status.HTTP_201_CREATED)
def create_community_comment(
    post_id: str,
    request: CommentCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, author_name = _profile_identity(claims)
    _active_post(db, post_id)
    comment = CommunityComment(
        id=str(uuid.uuid4()),
        post_id=post_id,
        profile_id=profile_id,
        author_name=author_name,
        body=_clean(request.body, "Comment text"),
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return {
        "success": True,
        "comment": _comment_dict(comment, profile_id),
    }


@router.post("/posts/{post_id}/report")
def report_community_post(
    post_id: str,
    request: ReportCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, _ = _profile_identity(claims)
    post = _active_post(db, post_id)
    if post.profile_id == profile_id:
        raise HTTPException(status_code=409, detail="You cannot report your own post.")

    existing = (
        db.query(CommunityReport)
        .filter(
            CommunityReport.post_id == post_id,
            CommunityReport.reporter_profile_id == profile_id,
        )
        .first()
    )
    if existing is not None:
        return {"success": True, "already_reported": True, "report_id": existing.id}

    report = CommunityReport(
        id=str(uuid.uuid4()),
        post_id=post_id,
        reporter_profile_id=profile_id,
        reason=request.reason,
        details=request.details.strip() if request.details and request.details.strip() else None,
    )
    db.add(report)
    try:
        db.commit()
    except IntegrityError:
        # Repeated or simultaneous reports by one profile do not create duplicates.
        db.rollback()
        existing = (
            db.query(CommunityReport)
            .filter(
                CommunityReport.post_id == post_id,
                CommunityReport.reporter_profile_id == profile_id,
            )
            .first()
        )
        if existing is None:
            raise
        return {"success": True, "already_reported": True, "report_id": existing.id}
    db.refresh(report)
    return {"success": True, "already_reported": False, "report_id": report.id, "status": report.status}


@router.post("/posts/{post_id}/hide")
def hide_community_post(
    post_id: str,
    claims: dict[str, Any] = Depends(authenticate_request),
    db: Session = Depends(get_db),
):
    profile_id, _ = _profile_identity(claims)
    post = _active_post(db, post_id)
    if post.profile_id != profile_id:
        raise HTTPException(status_code=403, detail="Only the author can hide this post.")
    post.status = "hidden"
    post.updated_at = datetime.now(post.created_at.tzinfo) if post.created_at and post.created_at.tzinfo else datetime.now()
    db.commit()
    return {"success": True, "post_id": post.id, "status": post.status}
