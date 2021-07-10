import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { BookAssociationComponent } from './book-association.component';

describe('BookAssociationComponent', () => {
  let component: BookAssociationComponent;
  let fixture: ComponentFixture<BookAssociationComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ BookAssociationComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(BookAssociationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
